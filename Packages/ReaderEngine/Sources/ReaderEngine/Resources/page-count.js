function reportPageCount(fragments) {
  async function report() {
    await document.fonts.ready;
    const pages = Math.round(document.scrollingElement.scrollWidth / window.innerWidth);
    webkit.messageHandlers.pageCount.postMessage({
      pages: Math.max(1, pages),
      fragmentPages: scholia.pagesOfElements(fragments),
    });
  }

  if (document.readyState === "complete") {
    report();
  } else {
    window.addEventListener("load", report);
  }
}
