import ready from 'util/ready';

// It toggles the aria-expanded attribute on click on elements with
// [data-behaviour='toggle-menu'].

// Optional: If data-follow-menu is set to 'right' or 'left' it will
// set its right or left style property to the element width that it controls (defined by the aria-controls).
// This is particularly useful to make a button follow the menu it controls

const attachButton = (element) => {
  const followMenu = element.getAttribute('data-follow-menu');

  if (followMenu === 'left' || followMenu === 'right') {
    const menuId = element.getAttribute('aria-controls');
    const menu = document.querySelector(`#${menuId}`);
    element.style.setProperty(followMenu, `${menu.offsetWidth}px`);
  }
};

ready(() => {
  const elements = document.querySelectorAll("[data-behaviour='toggle-menu']");

  elements.forEach((element) => {
    element.addEventListener('click', () => {
      const expanded = element.getAttribute('aria-expanded');

      if (expanded === 'false') {
        element.setAttribute('aria-expanded', 'true');
      } else {
        element.setAttribute('aria-expanded', 'false');
      }

      attachButton(element);
    });

    attachButton(element);
  });
});
