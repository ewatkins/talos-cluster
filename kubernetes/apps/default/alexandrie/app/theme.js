/*
 * Renames the app in the browser tab.
 *
 * The tab title is the one piece of branding CSS cannot reach. nginx rewrites
 * the server-rendered <title> so the first paint is already correct, but Nuxt
 * re-applies its own head on every client-side navigation -- unhead owns
 * document.title after hydration -- so the rewrite has to be re-asserted here.
 *
 * Only the two built-in brand titles are touched: the long one from
 * nuxt.config's app.head.title, and the bare "Alexandrie" the public pages
 * use. A document's own title (set by pages/dashboard/docs/[id].vue) is left
 * alone.
 */
(function () {
  var NAME = 'Notebook';
  var BRAND = /^Alexandrie(\s*\|.*)?$/;

  function rename() {
    // Assigning only on a match keeps this from re-triggering itself: the
    // observer fires again on the write, but 'Notebook' no longer matches.
    if (BRAND.test(document.title)) document.title = NAME;
  }

  rename();

  // childList catches unhead swapping the <title> element wholesale;
  // characterData catches it editing the text node in place.
  new MutationObserver(rename).observe(document.head, {
    subtree: true,
    childList: true,
    characterData: true,
  });
})();
