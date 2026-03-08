const menuButton = document.querySelector('[data-menu-button]');
const aside = document.querySelector('aside');

menuButton.addEventListener('click', function (e) {
    e.stopPropagation(); // Prevent event from bubbling up
    const isOpen = aside.classList.toggle('open');
    this.setAttribute('aria-expanded', isOpen);
});

// Optional: Close menu when clicking outside
document.addEventListener('click', function (e) {
    if (aside.classList.contains('open') && !aside.contains(e.target)) {
        aside.classList.remove('open');
        menuButton.setAttribute('aria-expanded', false);
    }
});