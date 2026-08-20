(() => {
  const reveal = () => {
    document.querySelectorAll("img.lazyload").forEach((img) => {
      const realSrc =
        img.getAttribute("data-src") ||
        img.getAttribute("data-original") ||
        img.currentSrc;
      if (realSrc && !img.getAttribute("src")) {
        img.setAttribute("src", realSrc);
      }
      img.classList.add("lazyloaded");
    });
  };

  const maybeReveal = () => {
    if (window.lazySizes) return;
    reveal();
  };

  if (document.readyState === "complete") {
    setTimeout(maybeReveal, 800);
  } else {
    window.addEventListener("load", () => setTimeout(maybeReveal, 800));
  }
})();
