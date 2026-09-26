(() => {
  async function report() {
    await document.fonts.ready;
    const pages = Math.round(document.scrollingElement.scrollWidth / window.innerWidth);
    webkit.messageHandlers.pageCount.postMessage(Math.max(1, pages));
  }

  if (document.readyState === "complete") {
    report();
  } else {
    window.addEventListener("load", report);
  }
})();
