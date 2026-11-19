document.addEventListener('click', (e) => {
  const dropdown = e.target.closest("[data-behaviour='dropdown']");

  if (dropdown) {
    const expanded = dropdown.getAttribute('aria-expanded');
    const parentMenu = dropdown.closest("[data-behaviour='menu-dropdown']");
    const parentMenuId = parentMenu ? parentMenu.id : null;

    if (expanded === 'false') {
      // Before expanding, close other dropdowns except parent (if nested)
      document.querySelectorAll("[data-behaviour='dropdown']").forEach((d) => {
        if (d.getAttribute('aria-controls') !== parentMenuId) {
          d.setAttribute('aria-expanded', 'false');
        }
      });
      dropdown.setAttribute('aria-expanded', 'true');
    } else {
      dropdown.setAttribute('aria-expanded', 'false');
      dropdown.blur();
    }
  } else {
    // Clicked outside any dropdown — close all
    document
      .querySelectorAll("[data-behaviour='dropdown']")
      .forEach((d) => d.setAttribute('aria-expanded', 'false'));
  }
});
