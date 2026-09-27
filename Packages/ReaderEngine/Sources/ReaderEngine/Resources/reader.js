(() => {
  const contextLength = 32;
  const softHyphen = /\u00AD/g;
  const rectTolerance = 1;
  const minimumBoxArea = 4;

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

  function almostEqual(a, b) {
    return Math.abs(a - b) <= rectTolerance;
  }

  function touchOrOverlap(first, second, isTolerant) {
    const near = (a, b) => isTolerant && almostEqual(a, b);
    return (
      (first.left < second.right || near(first.left, second.right)) &&
      (second.left < first.right || near(second.left, first.right)) &&
      (first.top < second.bottom || near(first.top, second.bottom)) &&
      (second.top < first.bottom || near(second.top, first.bottom))
    );
  }

  function rectangle(left, top, right, bottom) {
    return { left, top, right, bottom, width: right - left, height: bottom - top };
  }

  function containsRect(outer, inner) {
    const inside = (low, value, high) =>
      (low < value || almostEqual(low, value)) && (high > value || almostEqual(high, value));
    return (
      inside(outer.left, inner.left, outer.right) &&
      inside(outer.left, inner.right, outer.right) &&
      inside(outer.top, inner.top, outer.bottom) &&
      inside(outer.top, inner.bottom, outer.bottom)
    );
  }

  function mergeTouching(rects) {
    for (const [index, first] of rects.entries()) {
      for (const second of rects.slice(index + 1)) {
        const sameLine = almostEqual(first.top, second.top) && almostEqual(first.bottom, second.bottom);
        const sameColumn = almostEqual(first.left, second.left) && almostEqual(first.right, second.right);
        if (sameLine && !sameColumn && touchOrOverlap(first, second, true)) {
          const merged = rectangle(
            Math.min(first.left, second.left),
            Math.min(first.top, second.top),
            Math.max(first.right, second.right),
            Math.max(first.bottom, second.bottom)
          );
          return mergeTouching([...rects.filter((rect) => rect !== first && rect !== second), merged]);
        }
      }
    }
    return rects;
  }

  function removeContained(rects) {
    const kept = new Set(rects);
    for (const rect of rects) {
      if (rect.width <= rectTolerance || rect.height <= rectTolerance) {
        kept.delete(rect);
        continue;
      }
      if (rects.some((other) => other !== rect && kept.has(other) && containsRect(other, rect))) {
        kept.delete(rect);
      }
    }
    return Array.from(kept);
  }

  function subtract(rect, cut) {
    const left = Math.max(rect.left, cut.left);
    const right = Math.min(rect.right, cut.right);
    const top = Math.max(rect.top, cut.top);
    const bottom = Math.min(rect.bottom, cut.bottom);
    if (right <= left || bottom <= top) {
      return [rect];
    }
    return [
      rectangle(rect.left, rect.top, left, rect.bottom),
      rectangle(left, rect.top, right, top),
      rectangle(left, bottom, right, rect.bottom),
      rectangle(right, rect.top, rect.right, rect.bottom),
    ].filter((part) => part.width !== 0 && part.height !== 0);
  }

  function replaceOverlapping(rects) {
    for (const [index, first] of rects.entries()) {
      for (const second of rects.slice(index + 1)) {
        if (!touchOrOverlap(first, second, false)) {
          continue;
        }
        const firstParts = subtract(first, second);
        const secondParts = subtract(second, first);
        const [removed, added] =
          firstParts.length === 1 || firstParts.length < secondParts.length
            ? [first, firstParts]
            : [second, secondParts];
        return replaceOverlapping([...rects.filter((rect) => rect !== removed), ...added]);
      }
    }
    return rects;
  }

  function lineBoxes(range) {
    const rects = Array.from(range.getClientRects(), (rect) =>
      rectangle(rect.left, rect.top, rect.right, rect.bottom)
    );
    const kept = replaceOverlapping(removeContained(mergeTouching(rects)));
    const visible = kept.filter((rect) => rect.width * rect.height > minimumBoxArea);
    return (visible.length > 0 ? visible : kept.slice(0, 1)).sort((a, b) => a.top - b.top || a.left - b.left);
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

  function lastPageOfNode(node) {
    const range = document.createRange();
    range.selectNodeContents(node);
    const rects = boxes(range);
    return rects.length === 0 ? -1 : pageOf(rects[rects.length - 1]);
  }

  function offsetInNodeOfPage(node, page) {
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
    return low;
  }

  function endOfText(nodes) {
    const last = nodes[nodes.length - 1];
    return last ? last.start + last.node.data.length : 0;
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

  function lineAt(offset) {
    for (const { node, start } of textNodes()) {
      if (start + node.data.length <= offset) {
        continue;
      }
      const from = Math.max(0, offset - start);
      if (!boxOfCharacter(node, from)) {
        continue;
      }
      const textIndex = index(blockOf(node));
      const entry = textIndex.nodes.find((candidate) => candidate.node === node);
      const locale = canonicalLocale(document.documentElement.lang);
      const word = new Intl.Segmenter(locale, { granularity: "word" })
        .segment(textIndex.text)
        .containing(entry.start + from);
      const rest = textIndex.text
        .slice(word?.isWordLike ? word.index : entry.start + from)
        .replace(softHyphen, "")
        .replace(/\s+/g, " ")
        .trim();
      const sentence = new Intl.Segmenter(locale, { granularity: "sentence" }).segment(rest).containing(0);
      return sentence ? sentence.segment.trim() : "";
    }
    return "";
  }

  function pageOfOffset(offset) {
    if (offset <= 0) {
      return 0;
    }
    for (const { node, start } of textNodes()) {
      if (start + node.data.length <= offset) {
        continue;
      }
      const found = pageOfCharacter(node, Math.max(0, offset - start));
      if (found !== null) {
        return Math.min(found, lastPage());
      }
    }
    return lastPage();
  }

  function offsetOfRenderedText(offset) {
    for (const { node, start } of textNodes()) {
      if (start + node.data.length <= offset) {
        continue;
      }
      const from = Math.max(0, offset - start);
      if (boxOfCharacter(node, from)) {
        return start + from;
      }
    }
    return offset;
  }

  function offsetsOfElements(ids) {
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
      offsets[id] = text.trim() ? offsetOfRenderedText(text.length) : 0;
    }
    return offsets;
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

  const paintedClasses = {
    paintedHighlights: "scholia-highlight",
    paintedWordTints: "scholia-word-tap",
    paintedLive: "scholia-paint",
    paintedHighlightRings: "scholia-highlight-ring",
  };
  let press = null;
  let livePaint = null;
  let isHandlingPress = false;

  function caretAt(x, y) {
    const caret = document.caretRangeFromPoint(x, y);
    if (!caret || caret.startContainer.nodeType !== Node.TEXT_NODE) {
      return null;
    }
    const textIndex = index(blockOf(caret.startContainer));
    const offset = textIndex.nodes.find((entry) => entry.node === caret.startContainer).start + caret.startOffset;
    return { textIndex, offset };
  }

  function wordsAround(caret, locale) {
    const words = new Intl.Segmenter(locale, { granularity: "word" }).segment(caret.textIndex.text);
    return [caret.offset, caret.offset - 1]
      .map((offset) => (offset >= 0 ? words.containing(offset) : undefined))
      .filter((word) => word?.isWordLike)
      .map((word) => ({ word, range: range(caret.textIndex, word.index, word.index + word.segment.length) }));
  }

  function wordUnder(x, y, locale) {
    const caret = caretAt(x, y);
    for (const candidate of caret ? wordsAround(caret, locale) : []) {
      const rect = Array.from(candidate.range.getClientRects()).find((box) => contains(box, x, y));
      if (rect) {
        return { ...candidate, rect, textIndex: caret.textIndex };
      }
    }
    return null;
  }

  function wordNear(x, y, locale) {
    const caret = caretAt(x, y);
    if (!caret) {
      return null;
    }
    return wordsAround(caret, locale)[0]?.range ?? range(caret.textIndex, caret.offset, caret.offset);
  }

  function spanning(first, second) {
    const spanned = document.createRange();
    const start = first.compareBoundaryPoints(Range.START_TO_START, second) <= 0 ? first : second;
    const end = first.compareBoundaryPoints(Range.END_TO_END, second) >= 0 ? first : second;
    spanned.setStart(start.startContainer, start.startOffset);
    spanned.setEnd(end.endContainer, end.endOffset);
    return spanned;
  }

  function setSelectable(isSelectable) {
    if (isSelectable) {
      document.documentElement.style.removeProperty("-webkit-user-select");
    } else {
      document.documentElement.style.setProperty("-webkit-user-select", "none");
    }
  }

  function followPress() {
    if (!press || !livePaint?.isFollowing) {
      return;
    }
    press.frame = 0;
    const focus = wordNear(press.point.x, press.point.y, press.locale);
    if (focus) {
      livePaint.range = spanning(press.anchor, focus);
    }
    drawPaint();
  }

  function removePaint() {
    livePaint?.container.remove();
    livePaint = null;
  }

  function drawPaint() {
    const { scrollLeft, scrollTop } = document.scrollingElement;
    livePaint.container.replaceChildren(
      ...lineBoxes(livePaint.range).map((rect) => {
        const box = document.createElement("div");
        box.className = paintedClasses.paintedLive;
        Object.assign(box.style, {
          position: "absolute",
          left: `${rect.left + scrollLeft}px`,
          top: `${rect.top + scrollTop}px`,
          width: `${rect.width}px`,
          height: `${rect.height}px`,
          backgroundColor: livePaint.fill,
          borderRadius: `${livePaint.radius}px`,
          zIndex: "-1",
          pointerEvents: "none",
        });
        return box;
      })
    );
  }

  function addsHighlight(record) {
    const selector = `.${paintedClasses.paintedHighlights}`;
    return Array.from(record.addedNodes).some(
      (node) => node.nodeType === Node.ELEMENT_NODE && (node.matches(selector) || node.querySelector(selector))
    );
  }

  window.scholia = {
    offsetOfPage(page) {
      if (page <= 0) {
        return 0;
      }
      const nodes = textNodes();
      for (const { node, start } of nodes) {
        if (lastPageOfNode(node) >= page) {
          return start + offsetInNodeOfPage(node, page);
        }
      }
      return endOfText(nodes);
    },

    pageStarts() {
      const starts = [0];
      const pages = lastPage() + 1;
      const nodes = textNodes();
      for (const { node, start } of nodes) {
        const last = Math.min(lastPageOfNode(node), pages - 1);
        while (starts.length <= last) {
          starts.push(start + offsetInNodeOfPage(node, starts.length));
        }
      }
      while (starts.length < pages) {
        starts.push(endOfText(nodes));
      }
      return starts;
    },

    pageSpan(page) {
      const start = scholia.offsetOfPage(page);
      return { start, end: scholia.offsetOfPage(page + 1), firstLine: lineAt(start) };
    },

    async showOffset(offset) {
      await document.fonts.ready;
      const page = pageOfOffset(offset);
      const direction = isRightToLeft() ? -1 : 1;
      document.scrollingElement.scrollTo({ left: direction * page * window.innerWidth, behavior: "instant" });
      return page;
    },

    showPage(page) {
      const last = lastPage();
      const shown = page < 0 ? last : Math.min(page, last);
      const direction = isRightToLeft() ? -1 : 1;
      document.scrollingElement.scrollTo({ left: direction * shown * window.innerWidth, behavior: "instant" });
      return [shown, last + 1];
    },

    shownPage() {
      return Math.round(Math.abs(window.scrollX) / window.innerWidth);
    },

    async highlightsPainted(expected, timeout) {
      const deadline = performance.now() + timeout;
      const selector = `:has(> .${paintedClasses.paintedHighlights})`;
      while (document.querySelectorAll(selector).length < expected && performance.now() < deadline) {
        await nextFrame();
      }
      await nextFrame();
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

    visibleSpan() {
      const lineStart = isRightToLeft() ? window.innerWidth - 1 : 0;
      const lineEnd = window.innerWidth - 1 - lineStart;
      const start = offsetAt(lineStart, 0);
      const end = offsetAt(lineEnd, window.innerHeight - 1);
      return start === null || end === null ? null : { start, end, firstLine: lineAt(start) };
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

    offsetsOfElements,

    wordAt(x, y, language) {
      const locale = canonicalLocale(language);
      const found = wordUnder(x, y, locale);
      if (!found) {
        return null;
      }
      const { word, rect, textIndex } = found;
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
        range: quote(found.range),
      };
    },

    beginPress(x, y, language) {
      const locale = canonicalLocale(language);
      const anchor = wordUnder(x, y, locale)?.range;
      press = anchor ? { anchor, locale, point: null, frame: 0 } : null;
      isHandlingPress = press !== null;
    },

    selectPress() {
      const anchor = press?.anchor;
      press = null;
      if (!anchor) {
        return;
      }
      setSelectable(true);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(anchor);
    },

    startPainting(fill, radius) {
      removePaint();
      if (!press) {
        return;
      }
      const container = document.createElement("div");
      container.style.pointerEvents = "none";
      document.body.append(container);
      livePaint = { fill, radius, container, range: press.anchor, isFollowing: true };
      drawPaint();
    },

    paintTo(x, y) {
      if (!press || !livePaint?.isFollowing) {
        return;
      }
      press.point = { x, y };
      press.frame ||= requestAnimationFrame(followPress);
    },

    takePaint() {
      if (press?.frame) {
        cancelAnimationFrame(press.frame);
        followPress();
      }
      press = null;
      if (!livePaint?.isFollowing) {
        return null;
      }
      livePaint.isFollowing = false;
      return { range: quote(livePaint.range) };
    },

    stopPainting() {
      if (press?.frame) {
        cancelAnimationFrame(press.frame);
      }
      press = null;
      removePaint();
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

  const painted = { paintedHighlights: 0, paintedWordTints: 0, paintedLive: 0, paintedHighlightRings: 0 };
  new MutationObserver((records) => {
    if (livePaint && !livePaint.isFollowing && records.some(addsHighlight)) {
      removePaint();
    }
    for (const [name, className] of Object.entries(paintedClasses)) {
      const count = document.querySelectorAll(`:has(> .${className})`).length;
      if (count !== painted[name]) {
        painted[name] = count;
        webkit.messageHandlers[name].postMessage(count);
      }
    }
  }).observe(document.body, { childList: true, subtree: true });

  setSelectable(false);
  let selectionFrame = 0;
  let hasPostedSelection = false;
  window.addEventListener(
    "touchstart",
    () => {
      isHandlingPress = false;
    },
    { capture: true, passive: true }
  );
  window.addEventListener(
    "pointerup",
    (event) => {
      if (isHandlingPress) {
        event.stopImmediatePropagation();
        event.target.dispatchEvent(new PointerEvent("pointercancel", event));
      }
    },
    true
  );
  for (const type of ["mousedown", "click"]) {
    window.addEventListener(
      type,
      (event) => {
        if (isHandlingPress) {
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      },
      true
    );
  }

  document.addEventListener("selectionchange", () => {
    if (selectionFrame) {
      return;
    }
    selectionFrame = requestAnimationFrame(() => {
      selectionFrame = 0;
      const selected = selectedRange();
      if (!selected) {
        setSelectable(false);
      }
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
