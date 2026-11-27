/* The website in any of the app's twelve color schemes (#111, owner's
   request 2026-11-27: "What if clicking on the color scheme changed the
   entire website's color scheme to that scheme?").

   Loaded in every page's <head>, before the page draws, so a scheme picked
   earlier is in place on the first frame: it sets data-scheme on <html>,
   which site.css's generated blocks (tools/make_web_schemes.py) turn into
   that scheme's colors, and points the browser's own color-scheme and
   theme-color at it. On the landing page it makes the twelve pictures in
   the color schemes band into buttons that pick one; Black, the site as
   written, takes the stored pick away. The pick is kept in this browser
   only (localStorage), never sent anywhere. Without this script, or with
   storage blocked, the site is Black, as it was before. The screenshots
   don't change: they show the app as it is. */
(function () {
  var KEY = "battleplan-scheme";
  var SCHEMES = ["dark", "army", "light", "skyblue", "candypop", "graphite", "navy", "darkarmy", "wildcat", "purplegold", "deserttan", "sugarrush"];
  var root = document.documentElement;

  function stored() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function store(value) {
    try {
      if (value === "dark") localStorage.removeItem(KEY);
      else localStorage.setItem(KEY, value);
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

  function apply(value) {
    if (SCHEMES.indexOf(value) < 1) root.removeAttribute("data-scheme");
    else root.setAttribute("data-scheme", value);
  }

  function current() {
    return root.getAttribute("data-scheme") || "dark";
  }

  apply(stored());

  // Again once the stylesheet is in: at DOMContentLoaded it may still be
  // loading.
  window.addEventListener("load", syncMeta);

  document.addEventListener("DOMContentLoaded", function () {
    syncMeta();
    var buttons = document.querySelectorAll(".lp-look[data-scheme]");
    if (!buttons.length) return;
    var hint = document.querySelector(".lp-try");
    if (hint) hint.hidden = false;
    function mark() {
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].setAttribute("aria-pressed", String(buttons[i].getAttribute("data-scheme") === current()));
      }
    }
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
