import ready from 'util/ready';

const initDropdowns = (dropdowns) => {
  dropdowns.forEach((dropdown) => {
    const parentMenu = dropdown.closest("[data-behaviour='menu-dropdown']");
    const parentMenuId = parentMenu ? parentMenu.id : null;

    dropdown.addEventListener('click', () => {
      const expanded = dropdown.getAttribute('aria-expanded');

      if (expanded === 'false') {
        // Before expanding the dropdown, close other dropdowns except for its parent (if nested)
        const dropdownsWithoutParent = Array.from(dropdowns).filter(
          (d) => d.getAttribute('aria-controls') !== parentMenuId,
        );
        dropdownsWithoutParent.forEach((d) =>
          d.setAttribute('aria-expanded', 'false'),
        );
        dropdown.setAttribute('aria-expanded', 'true');
      } else {
        dropdown.setAttribute('aria-expanded', 'false');
        dropdown.blur();
      }
    });
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    const isDropdown = e.target.getAttribute('data-behaviour') === 'dropdown';
    const isInsideDropdown = e.target.closest("[data-behaviour='dropdown']");

    if (isDropdown || isInsideDropdown) return;

    dropdowns.forEach((d) => d.setAttribute('aria-expanded', 'false'));
  });
};

ready(() => {
  const dropdowns = document.querySelectorAll("[data-behaviour='dropdown']");

  initDropdowns(dropdowns);
});

export default initDropdowns;
