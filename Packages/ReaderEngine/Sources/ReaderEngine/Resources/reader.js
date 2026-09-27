(() => {
  const contextLength = 32;
  const softHyphen = /\u00AD/g;

  function blockOf(node) {
    let element = node.parentElement;
    while (element !== document.body && getComputedStyle(element).display.startsWith("inline")) {
      element = element.parentElement;
    }
    return element;
  }

  function index(block) {
    const walker = document.createTreeWalker(block, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
    const nodes = [];
    let text = "";
    let previousBlock = block;
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (node.nodeType === Node.ELEMENT_NODE) {
        if (node.localName === "br") {
          text += " ";
        }
        continue;
      }
      const nodeBlock = blockOf(node);
      if (nodeBlock !== previousBlock) {
        text += "\n";
        previousBlock = nodeBlock;
      }
      nodes.push({ node, start: text.length });
      text += node.data;
    }
    return { text, nodes };
  }

  function boundary(textIndex, offset) {
    const entry = textIndex.nodes.findLast((candidate) => candidate.start <= offset);
    return { node: entry.node, offset: offset - entry.start };
  }

  function range(textIndex, start, end) {
    const result = document.createRange();
    const from = boundary(textIndex, start);
    const to = boundary(textIndex, end);
    result.setStart(from.node, from.offset);
    result.setEnd(to.node, to.offset);
    return result;
  }

  function contains(rect, x, y) {
    return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
  }

  function canonicalLocale(language) {
    try {
      return Intl.getCanonicalLocales(language?.replaceAll("_", "-"))[0];
    } catch {
      return undefined;
    }
  }

  function textNodes() {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const nodes = [];
    let start = 0;
    while (walker.nextNode()) {
      nodes.push({ node: walker.currentNode, start });
      start += walker.currentNode.data.length;
    }
    return nodes;
  }

  function isRightToLeft() {
    return getComputedStyle(document.documentElement).direction === "rtl";
  }

  function pageOf(rect) {
    const width = window.innerWidth;
    return isRightToLeft()
      ? Math.floor((width - rect.right - window.scrollX) / width)
      : Math.floor((rect.left + window.scrollX) / width);
  }

  function boxes(range) {
    return Array.from(range.getClientRects()).filter((rect) => rect.width > 0 || rect.height > 0);
  }

  function boxOfCharacter(node, from) {
    const range = document.createRange();
    for (let index = from; index < node.data.length; index++) {
      range.setStart(node, index);
      range.setEnd(node, index + 1);
      const rect = boxes(range)[0];
      if (rect) {
        return rect;
      }
    }
    return null;
  }

  function pageOfCharacter(node, from) {
    const rect = boxOfCharacter(node, from);
    return rect ? pageOf(rect) : null;
  }

  function lastPage() {
    return Math.max(0, Math.round(document.scrollingElement.scrollWidth / window.innerWidth) - 1);
  }

  function hex(color) {
    const channels = (color.match(/[\d.]+/g) ?? []).slice(0, 3).map(Number);
    return "#" + channels.map((channel) => Math.round(channel).toString(16).padStart(2, "0")).join("");
  }

  function sameColor(a, b) {
    return [1, 3, 5].every((index) => Math.abs(parseInt(a.substr(index, 2), 16) - parseInt(b.substr(index, 2), 16)) <= 1);
  }

  function firstFamily(family) {
    return family.split(",")[0].trim().replace(/^["']|["']$/g, "");
  }

  function nextFrame() {
    return new Promise((resolve) => requestAnimationFrame(() => resolve()));
  }

  function offsetAt(x, y) {
    const caret = document.caretRangeFromPoint(x, y);
    if (!caret) {
      return null;
    }
    const before = document.createRange();
    before.setStart(document.body, 0);
    before.setEnd(caret.startContainer, caret.startOffset);
    return before.toString().length;
  }

  function quote(selected) {
    const prefix = document.createRange();
    prefix.setStart(document.body, 0);
    prefix.setEnd(selected.startContainer, selected.startOffset);
    const start = prefix.toString().length;
    const text = selected.toString();
    const end = start + text.length;
    const body = document.body.textContent;
    return {
      text,
      start,
      end,
      before: body.slice(Math.max(0, start - contextLength), start),
      after: body.slice(end, end + contextLength),
    };
  }

  function selectedRange() {
    const selection = window.getSelection();
    if (!selection || selection.isCollapsed || selection.rangeCount === 0) {
      return null;
    }
    const selected = selection.getRangeAt(0);
    return selected.toString().trim() === "" ? null : selected;
  }

  function sentenceOf(quoted, language) {
    const selected = quoted.text.replace(softHyphen, "");
    const word = selected.trim();
    const nodes = textNodes();
    const first = nodes.find(({ node, start }) => quoted.start < start + node.data.length);
    const last = nodes.findLast(({ start }) => start < quoted.end);
    if (!first || !last || blockOf(first.node) !== blockOf(last.node)) {
      return { word, sentence: word, offsetInSentence: 0 };
    }
    const textIndex = index(blockOf(first.node));
    const blockStart = (entry) => textIndex.nodes.find((candidate) => candidate.node === entry.node).start;
    const from = blockStart(first) + quoted.start - first.start;
    const to = blockStart(last) + quoted.end - last.start;
    const sentences = new Intl.Segmenter(canonicalLocale(language), { granularity: "sentence" }).segment(
      textIndex.text
    );
    const opening = sentences.containing(from);
    const closing = sentences.containing(Math.max(from, to - 1));
    if (!opening || !closing) {
      return { word, sentence: word, offsetInSentence: 0 };
    }
    const leading = selected.slice(0, selected.length - selected.trimStart().length);
    const prefix = textIndex.text.slice(opening.index, from).replace(softHyphen, "") + leading;
    return {
      word,
      sentence: textIndex.text
        .slice(opening.index, closing.index + closing.segment.length)
        .replace(softHyphen, "")
        .trim(),
      offsetInSentence: prefix.trimStart().length,
    };
  }

  window.scholia = {
    offsetOfPage(page) {
      if (page <= 0) {
        return 0;
      }
      const nodes = textNodes();
      for (const { node, start } of nodes) {
        const range = document.createRange();
        range.selectNodeContents(node);
        const rects = boxes(range);
        if (rects.length === 0 || pageOf(rects[rects.length - 1]) < page) {
          continue;
        }
        let low = 0;
        let high = node.data.length - 1;
        while (low < high) {
          const middle = (low + high) >> 1;
          const found = pageOfCharacter(node, middle);
          if (found === null || found >= page) {
            high = middle;
          } else {
            low = middle + 1;
          }
        }
        return start + low;
      }
      const last = nodes[nodes.length - 1];
      return last ? last.start + last.node.data.length : 0;
    },

    async showOffset(offset) {
      await document.fonts.ready;
      let page = 0;
      if (offset > 0) {
        page = lastPage();
        for (const { node, start } of textNodes()) {
          if (start + node.data.length <= offset) {
            continue;
          }
          const found = pageOfCharacter(node, Math.max(0, offset - start));
          if (found !== null) {
            page = Math.min(found, page);
            break;
          }
        }
      }
      const direction = isRightToLeft() ? -1 : 1;
      document.scrollingElement.scrollTo({ left: direction * page * window.innerWidth, behavior: "instant" });
      return page;
    },

    async scrollToOffset(offset) {
      await document.fonts.ready;
      for (const { node, start } of textNodes()) {
        if (start + node.data.length <= offset) {
          continue;
        }
        const rect = boxOfCharacter(node, Math.max(0, offset - start));
        if (rect) {
          document.scrollingElement.scrollTo({ top: rect.top + window.scrollY, behavior: "instant" });
          return;
        }
      }
    },

    visibleOffsets() {
      const lineStart = isRightToLeft() ? window.innerWidth - 1 : 0;
      const lineEnd = window.innerWidth - 1 - lineStart;
      const start = offsetAt(lineStart, 0);
      const end = offsetAt(lineEnd, window.innerHeight - 1);
      return start === null || end === null ? null : [start, end];
    },

    style() {
      const page = getComputedStyle(document.documentElement);
      const text = getComputedStyle(document.querySelector("p") ?? document.body);
      return {
        background: hex(page.backgroundColor),
        text: hex(text.color),
        fontFamily: firstFamily(text.fontFamily),
        fontSize: parseFloat(text.fontSize),
        lineHeight: parseFloat(text.lineHeight),
      };
    },

    async rendered(expected, timeout) {
      const deadline = performance.now() + timeout;
      const matches = (style) =>
        sameColor(style.background, expected.background) &&
        sameColor(style.text, expected.text) &&
        style.fontFamily === expected.fontFamily;
      while (!matches(scholia.style()) && performance.now() < deadline) {
        await nextFrame();
      }
      document.body.getBoundingClientRect();
      await document.fonts.ready;
      await nextFrame();
      await nextFrame();
    },

    offsetsOfElements(ids) {
      const offsets = {};
      for (const id of ids) {
        const element = document.getElementById(id);
        if (!element) {
          continue;
        }
        const before = document.createRange();
        before.setStart(document.body, 0);
        before.setEndBefore(element);
        const text = before.toString();
        offsets[id] = text.trim() ? text.length : 0;
      }
      return offsets;
    },

    wordAt(x, y, language) {
      const caret = document.caretRangeFromPoint(x, y);
      if (!caret || caret.startContainer.nodeType !== Node.TEXT_NODE) {
        return null;
      }
      const textIndex = index(blockOf(caret.startContainer));
      const caretOffset =
        textIndex.nodes.find((entry) => entry.node === caret.startContainer).start + caret.startOffset;
      const locale = canonicalLocale(language);
      const words = new Intl.Segmenter(locale, { granularity: "word" }).segment(textIndex.text);
      for (const offset of [caretOffset, caretOffset - 1]) {
        const word = offset >= 0 ? words.containing(offset) : undefined;
        if (!word || !word.isWordLike) {
          continue;
        }
        const end = word.index + word.segment.length;
        const wordRange = range(textIndex, word.index, end);
        const rect = Array.from(wordRange.getClientRects()).find((candidate) => contains(candidate, x, y));
        if (!rect) {
          continue;
        }
        const sentence = new Intl.Segmenter(locale, { granularity: "sentence" })
          .segment(textIndex.text)
          .containing(word.index);
        return {
          text: word.segment.replace(softHyphen, ""),
          sentence: sentence.segment.replace(softHyphen, "").trim(),
          offsetInSentence: textIndex.text.slice(sentence.index, word.index).replace(softHyphen, "").trimStart().length,
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
          range: quote(wordRange),
        };
      }
      return null;
    },

    takeSelection(language) {
      const selected = selectedRange();
      window.getSelection()?.removeAllRanges();
      if (!selected) {
        return null;
      }
      const rect = selected.getBoundingClientRect();
      const quoted = quote(selected);
      return {
        ...sentenceOf(quoted, language),
        range: quoted,
        x: rect.left,
        y: rect.top,
        width: rect.width,
        height: rect.height,
      };
    },
  };

  const painted = { paintedHighlights: 0, paintedWordTints: 0 };
  const paintedClasses = { paintedHighlights: "scholia-highlight", paintedWordTints: "scholia-word-tap" };
  new MutationObserver(() => {
    for (const [name, className] of Object.entries(paintedClasses)) {
      const count = document.querySelectorAll(`:has(> .${className})`).length;
      if (count !== painted[name]) {
        painted[name] = count;
        webkit.messageHandlers[name].postMessage(count);
      }
    }
  }).observe(document.body, { childList: true, subtree: true });

  let selectionFrame = 0;
  let hasPostedSelection = false;
  document.addEventListener("selectionchange", () => {
    if (selectionFrame) {
      return;
    }
    selectionFrame = requestAnimationFrame(() => {
      selectionFrame = 0;
      const selected = selectedRange();
      if (!selected && !hasPostedSelection) {
        return;
      }
      hasPostedSelection = selected !== null;
      const rect = selected?.getBoundingClientRect();
      webkit.messageHandlers.scholiaSelection.postMessage(
        selected && {
          text: selected.toString().replace(softHyphen, ""),
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
        }
      );
    });
  });
})();
