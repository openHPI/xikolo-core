/**
 * Append data to DOM element on ajax success event
 *
 * Adding the attribute data-render-to to a form that uses "remote: true" (the way ruby
 * on rails submits forms by Ajax) will append the data from the request to the DOM element
 * defined by the attribute.
 *
 */

import $ from 'jquery';
import ready from '../../util/ready';

ready(() => {
  $(document).on('ajax:success', '[data-render-to]', (event: CustomEvent) => {
    const target = event.target as HTMLElement;
    const data = event.detail as string;

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
