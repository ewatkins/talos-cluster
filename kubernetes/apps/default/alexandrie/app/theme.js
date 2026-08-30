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
   * Put the document's own icon in the header.
   *
   * Node/Document/Header.vue renders no icon of its own -- it teleports the
   * *category* icon out to #navbar-title -- and an icon here is an SVG sprite
   * reference (<svg class="icon"><use href="#icon-file"></svg>), which CSS
   * cannot conjure. So the node is cloned out of the sidebar, where every
   * document already renders its own icon.
   *
   * SidebarItem.vue shapes each row as
   *   <span class="item"><Icon/><a href="/dashboard/docs/:id">label</a>...</span>
   * so the row for the open document is the one whose link href matches the
   * current path, and its first <svg> is the file icon. Cloning it carries
   * the colour along: role 3 nodes get an inline pink fill, categories get an
   * accent class.
   *
   * The wrapper is drawn as a circle by .doc-header-icon in theme.css.
   */
  var HOST_CLASS = 'doc-header-icon';

  function sidebarIcon() {
    var links = document.querySelectorAll('.sidebar .item a[href]');
    for (var i = 0; i < links.length; i++) {
      // Exact path rather than :is(.router-link-active): Vue Router marks
      // ancestor routes active too, which would match parent categories.
      if (links[i].getAttribute('href') !== location.pathname) continue;
      var row = links[i].closest('.item');
      var svg = row && row.querySelector('svg');
      if (svg) return svg;
    }
    // Collapsed branch, filtered tree, or a view with no sidebar row at all.
    // The navbar's category icon is the next best thing.
    return document.querySelector('#navbar-title svg');
  }

  function placeIcon() {
    var infos = document.querySelector('.doc-container > .header .infos');
    if (!infos) return;

    var existing = infos.querySelector('.' + HOST_CLASS);
    var source = sidebarIcon();

    // Not a document view, or the icon has not rendered yet.
    if (!source) {
      if (existing) existing.remove();
      return;
    }

    // Compare the markup itself rather than the sprite reference: Vue sets
    // the <use> target as a namespaced xlink:href, which is not reliably
    // readable back with getAttribute, and an unreadable key made this
    // bail out every time.
    var key = source.outerHTML;

    // Already showing this icon. The early return is what keeps the observer
    // below from looping on its own insertion.
    if (existing && existing.getAttribute('data-icon') === key) return;
    if (existing) existing.remove();

    var host = document.createElement('span');
    host.className = HOST_CLASS;
    host.setAttribute('data-icon', key);
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
