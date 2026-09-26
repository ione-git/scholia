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
        const rect = Array.from(range(textIndex, word.index, end).getClientRects()).find((candidate) =>
          contains(candidate, x, y)
        );
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
          before: textIndex.text.slice(Math.max(0, word.index - contextLength), word.index),
          after: textIndex.text.slice(end, end + contextLength),
        };
      }
      return null;
    },

    takeSelection() {
      const selection = window.getSelection();
      if (!selection || selection.isCollapsed) {
        return null;
      }
      const selected = selection.getRangeAt(0);
      const before = document.createRange();
      before.setStart(document.body, 0);
      before.setEnd(selected.startContainer, selected.startOffset);
      const after = document.createRange();
      after.setStart(selected.endContainer, selected.endOffset);
      after.setEnd(document.body, document.body.childNodes.length);
      const text = selected.toString();
      selection.removeAllRanges();
      return {
        text: text,
        before: before.toString().slice(-contextLength),
        after: after.toString().slice(0, contextLength),
      };
    },
  };

  let paintedHighlights = 0;
  new MutationObserver(() => {
    const count = document.querySelectorAll(":has(> .scholia-highlight)").length;
    if (count !== paintedHighlights) {
      paintedHighlights = count;
      webkit.messageHandlers.paintedHighlights.postMessage(count);
    }
  }).observe(document.body, { childList: true, subtree: true });
})();
