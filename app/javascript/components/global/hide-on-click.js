/**
 * Click on a DOM element to hide another
 *
 * The click trigger is specified with the hide-on-click data attribute
 * The value of it will specify the target that will be hidden
 */

import { turboReady } from '../../util/ready';

document.addEventListener('turbo:before-cache', () => {
  document.querySelectorAll('[data-hide-on-click]').forEach((trigger) => {
    const target = document.querySelector(trigger.dataset.hideOnClick);
    if (target) target.hidden = false;
  });
});

turboReady(() => {
  const triggers = document.querySelectorAll('[data-hide-on-click]');

  triggers.forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const target = document.querySelector(trigger.dataset.hideOnClick);
      target.hidden = true;
    });
  });
});
