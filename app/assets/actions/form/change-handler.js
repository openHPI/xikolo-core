/**
 * Input element change handler
 *
 * Inputs with a `data-change` attribute are automatically handled
 * based on the action in the value of the data attribute.
 * Supports plain JS change events.
 *
 * Currently available action values:
 * - 'submit': submits the form containing the attributed input
 * - 'redirect': redirects to the path defined as the value of the target event
 *
 * Can be extended with further action types or suitable events.
 */

import ready from 'util/ready';

ready(() => {
  function handleChange(event) {
    const el = event.target;

    switch (el.dataset.change) {
      case 'submit':
        el.closest('form').requestSubmit();
        break;
      case 'redirect': {
        window.location.href = el.value;
        break;
      }
      default:
        break;
    }
  }

  document.addEventListener('change', (e) => {
    if (e.target.matches('[data-change]')) {
      handleChange(e);
    }
  });
});
