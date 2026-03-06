/*!
 * Minimal theme switcher
 *
 * Pico.css - https://picocss.com
 * Copyright 2020 - Licensed under MIT
 */

const themeSwitcher = {
    // Config
    buttonsTarget: "a[data-theme-switcher]",
    buttonAttribute: "data-theme-switcher",
    rootAttribute: "data-theme",
  
    // Init
    init() {
      // Restore saved theme on page load
      const saved = localStorage.getItem('theme');
      if (saved) {
        document.querySelector("html").setAttribute(this.rootAttribute, saved);
      }

      document.querySelectorAll(this.buttonsTarget).forEach(
        function (button) {
          button.addEventListener(
            "click",
            function (event) {
              event.preventDefault();
              const theme = event.target.getAttribute(this.buttonAttribute);
              document.querySelector("html").setAttribute(this.rootAttribute, theme);
              if (theme) localStorage.setItem('theme', theme);
            }.bind(this),
            false
          );
        }.bind(this)
      );
    },
  };

// Init
themeSwitcher.init();