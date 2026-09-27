function reportPageCount(fragments) {
  async function report() {
    await document.fonts.ready;
    webkit.messageHandlers.pageCount.postMessage({
      pageStarts: scholia.pageStarts(),
      fragmentOffsets: scholia.offsetsOfElements(fragments),
    });
  }

  if (document.readyState === "complete") {
    report();
  } else {
    window.addEventListener("load", report);
  }
}
