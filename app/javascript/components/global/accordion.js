import ready from '../../util/ready';

// The component with the data-controller 'accordion'
// expands one item on button click
// and collapses all other elements

ready(() => {
  const components = document.querySelectorAll("[data-controller='accordion']");

  components.forEach((component) => {
    const elements = component.querySelectorAll(
      "[data-accordion-target='toggle-button']",
    );
    elements.forEach((element) => {
      element.addEventListener('click', () => {
        const expanded = element.getAttribute('aria-expanded');

        elements.forEach((el) => {
          el.setAttribute('aria-expanded', 'false');
        });

        if (expanded === 'false') {
          element.setAttribute('aria-expanded', 'true');
        } else {
          element.setAttribute('aria-expanded', 'false');
        }
      });
    });
  });
});
