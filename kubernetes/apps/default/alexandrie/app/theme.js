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

  /*
   * Put the category icon in the document header.
   *
   * Node/Document/Header.vue teleports the icon out to #navbar-title, so the
   * header itself has no icon to style -- and the icon is an SVG sprite
   * reference (<svg class="icon xl"><use href="#icon-network"></svg>), which
   * CSS cannot conjure. So the navbar's node is cloned back in. The clone
   * keeps the accent class, so it stays the category's colour.
   *
   * The wrapper is drawn as a circle by .doc-header-icon in theme.css.
   */
  var HOST_CLASS = 'doc-header-icon';

  function iconRef(svg) {
    var use = svg && svg.querySelector('use');
    if (!use) return '';
    return use.getAttribute('xlink:href') || use.getAttribute('href') || '';
  }

  function placeIcon() {
    var infos = document.querySelector('.doc-container > .header .infos');
    if (!infos) return;

    var existing = infos.querySelector('.' + HOST_CLASS);
    var source = document.querySelector('#navbar-title svg');
    var ref = iconRef(source);

    // Not a document view, or the icon has not rendered yet.
    if (!source || !ref) {
      if (existing) existing.remove();
      return;
    }

    // Already showing this icon. The early return is what keeps the observer
    // below from looping on its own insertion.
    if (existing && existing.getAttribute('data-icon') === ref) return;
    if (existing) existing.remove();

    var host = document.createElement('span');
    host.className = HOST_CLASS;
    host.setAttribute('data-icon', ref);
    host.setAttribute('aria-hidden', 'true');
    host.appendChild(source.cloneNode(true));
    infos.insertBefore(host, infos.firstChild);
  }

  // Vue re-renders the header on every navigation, so this has to be
  // re-applied rather than run once. Coalesced into a frame because a body
  // observer fires constantly while the editor is open.
  var queued = false;
  function schedule() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () {
      queued = false;
      placeIcon();
    });
  }

  schedule();
  new MutationObserver(schedule).observe(document.body, { subtree: true, childList: true });
})();
