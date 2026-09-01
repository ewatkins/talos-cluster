/*
 * Renames the app in the browser tab and pins its favicon.
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

  // Alexandrie ships two marks: favicon.ico is #334155 slate, meant for a
  // light tab strip, and favicon-dark.ico is near-white for a dark one.
  var ICON = '/favicon-dark.ico';

  function rename() {
    // Assigning only on a match keeps this from re-triggering itself: the
    // observer fires again on the write, but 'Notebook' no longer matches.
    if (BRAND.test(document.title)) document.title = NAME;
  }

  /*
   * Hold the favicon on the light-on-dark mark.
   *
   * The app chooses between its two icons from the OS colour scheme: the
   * server-rendered head carries both links switched by a `media` attribute,
   * and on hydration a matchMedia listener rewrites link[rel=icon].href on
   * every change. This instance renders dark whatever the OS says, so the
   * slate one is always wrong here. nginx injects the link so the first
   * request is already for the right file; this is what keeps it there.
   */
  function pinIcon() {
    var links = document.head.querySelectorAll('link[rel~="icon"]');
    for (var i = 0; i < links.length; i++) {
      // The server-rendered pair is switched by `media`, not by href.
      // Dropping it leaves both links unconditional and on the same file.
      if (links[i].hasAttribute('media')) links[i].removeAttribute('media');
      // Only on a mismatch, so the observer's re-fire on our own write is a
      // no-op rather than a loop.
      if (links[i].getAttribute('href') !== ICON) links[i].setAttribute('href', ICON);
    }
  }

  function apply() {
    rename();
    pinIcon();
  }

  apply();

  // childList catches unhead swapping the <title> element wholesale, or the
  // app appending an icon link that was not in the markup; characterData
  // catches unhead editing the title text node in place; the attribute filter
  // catches the hydration listener rewriting an existing icon link, which is
  // an attribute change and would otherwise go unseen.
  new MutationObserver(apply).observe(document.head, {
    subtree: true,
    childList: true,
    characterData: true,
    attributes: true,
    attributeFilter: ['href', 'media'],
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
   * current path, and its first .icon is the file icon. Cloning it carries
   * the colour along: role 3 nodes get an inline pink fill, categories get an
   * accent class.
   *
   * The .icon element and not the <svg> inside it. Icon.vue renders a sprite
   * as <svg class="icon"><use/></svg> but an icon stored as raw markup as
   * <i class="icon c-icon"><svg/></i>, and it is the wrapper that carries the
   * classes and the inline colour theme.css keys on -- reaching past it to
   * the <svg> dropped both on the raw-markup branch.
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
      var icon = row && row.querySelector('.icon');
      if (icon) return icon;
    }
    // Collapsed branch, filtered tree, or a view with no sidebar row at all.
    // The navbar's category icon is the next best thing.
    return document.querySelector('#navbar-title .icon') || document.querySelector('#navbar-title svg');
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
