/**
 * Append data to DOM element on ajax success event
 *
 * Adding the attribute data-render-to to a form that uses "remote: true" (the way ruby
 * on rails submits forms by Ajax) will append the data from the request to the DOM element
 * defined by the attribute.
 *
 */

import ready from '../../util/ready';

ready(() => {
  // ------------------------
  // HACK: jQuery comes from Sprockets assets.
  // ------------------------
  // eslint-disable-next-line no-undef
  const $ = jQuery;

  $(document).on('ajax:success', '[data-render-to]', (event, data) => {
    const target = event.target as HTMLElement;

    if (target instanceof HTMLElement && target.matches('[data-render-to]')) {
      const selector = target.getAttribute('data-render-to');

      if (selector) {
        const renderTarget = document.querySelector(selector);
        if (renderTarget) {
          renderTarget.innerHTML = data;
        }
      }
    }
  });
});
