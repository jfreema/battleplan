/* The website in any of the app's twelve color schemes (#111, owner's
   request 2026-11-27: "What if clicking on the color scheme changed the
   entire website's color scheme to that scheme?").

   Army green is the site's default (#118, owner's request the same day:
   "let's make the army green one the default theme for now. dont change
   the order theyre displayed on the site, just have the army green one
   selected by default. it should clear for a user on the website after a
   while and not persist for more than a day if possible."). Every page's
   <html> says data-scheme="army", so that holds with scripts off too, and
   this script takes the default from there: to change it, change the
   pages.

   Loaded in every page's <head>, before the page draws, so a scheme picked
   earlier is in place on the first frame: it sets data-scheme on <html>,
   which site.css's generated blocks (tools/make_web_schemes.py) turn into
   that scheme's colors (no data-scheme is Black, the colors site.css is
   written in), and points the browser's own color-scheme and theme-color
   at it. On the landing page it makes the twelve pictures in the color
   schemes band into buttons that pick one; the default takes the stored
   pick away. The pick is kept in this browser only (localStorage), never
   sent anywhere, with the time it was made, and for a day at most: after
   that it is taken away and the site is the default again. Without this
   script, or with storage blocked, the site is the default. The
   screenshots don't change: they show the app as it is. */
(function () {
  var KEY = "battleplan-scheme";
  // How long a pick lasts: a day.
  var KEEP_MS = 24 * 60 * 60 * 1000;
  var SCHEMES = ["dark", "army", "light", "skyblue", "candypop", "graphite", "navy", "darkarmy", "wildcat", "purplegold", "deserttan", "sugarrush"];
  var root = document.documentElement;
  // The site's default: what the page's own markup says, or Black if it
  // says nothing (or names a scheme that's gone).
  var DEFAULT = SCHEMES.indexOf(root.getAttribute("data-scheme")) < 0 ? "dark" : root.getAttribute("data-scheme");

  // The pick, if one was made in the last day. It's stored as
  // "<scheme>|<when it was picked, in milliseconds>"; anything else (a pick
  // from before picks had a time, a time in the future, a scheme that's
  // gone) is taken away, as one older than a day is.
  function stored() {
    try {
      var raw = localStorage.getItem(KEY);
      if (raw === null) return null;
      var parts = raw.split("|");
      var age = Date.now() - Number(parts[1]);
      if (parts.length === 2 && SCHEMES.indexOf(parts[0]) >= 0 && age >= 0 && age < KEEP_MS) return parts[0];
      localStorage.removeItem(KEY);
    } catch (e) { /* Storage blocked: the default. */ }
    return null;
  }

  function store(value) {
    try {
      if (value === DEFAULT) localStorage.removeItem(KEY);
      else localStorage.setItem(KEY, value + "|" + Date.now());
    } catch (e) { /* Storage blocked: the pick lasts for this page. */ }
  }

  // The browser's own colors: the scroll bars and form controls, and the
  // phone's bar over the page, follow the scheme.
  function syncMeta() {
    var css = getComputedStyle(root);
    var cs = document.querySelector('meta[name="color-scheme"]');
    var tc = document.querySelector('meta[name="theme-color"]');
    if (cs) cs.setAttribute("content", (css.colorScheme || "dark").trim());
    if (tc) tc.setAttribute("content", css.getPropertyValue("--band").trim() || "#070707");
  }

  // Puts the page in [value], or in the default when it isn't a scheme.
  function apply(value) {
    if (SCHEMES.indexOf(value) < 0) value = DEFAULT;
    if (value === "dark") root.removeAttribute("data-scheme");
    else root.setAttribute("data-scheme", value);
  }

  function current() {
    return root.getAttribute("data-scheme") || "dark";
  }

  // Marks the band's button for the scheme the page is in; set once the
  // page has its buttons.
  var mark = function () {};

  apply(stored());

  // Again once the stylesheet is in: at DOMContentLoaded it may still be
  // loading.
  window.addEventListener("load", syncMeta);

  // A page the browser kept and shows again (Back, Forward) looks at the
  // pick again: it may have run out, or changed on another page.
  window.addEventListener("pageshow", function (event) {
    if (!event.persisted) return;
    apply(stored());
    syncMeta();
    mark();
  });

  document.addEventListener("DOMContentLoaded", function () {
    syncMeta();
    var buttons = document.querySelectorAll(".lp-look[data-scheme]");
    if (!buttons.length) return;
    var hint = document.querySelector(".lp-try");
    if (hint) hint.hidden = false;
    mark = function () {
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].setAttribute("aria-pressed", String(buttons[i].getAttribute("data-scheme") === current()));
      }
    };
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].disabled = false;
      buttons[i].addEventListener("click", function () {
        var value = this.getAttribute("data-scheme");
        apply(value);
        store(value);
        syncMeta();
        mark();
      });
    }
    mark();
  });
})();
