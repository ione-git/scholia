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

  window.scholia = {
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
})();
