/**
 * Click on a DOM element to show another
 *
 * The click trigger is specified with the show-on-click data attribute
 * The value of it will specify the target that will be shown
 */

import { turboReady } from '../../util/ready';

document.addEventListener('turbo:before-cache', () => {
  document.querySelectorAll('[data-show-on-click]').forEach((trigger) => {
    const target = document.querySelector(trigger.dataset.showOnClick);
    if (target) target.hidden = true;
  });
});

turboReady(() => {
  const triggers = document.querySelectorAll('[data-show-on-click]');

  triggers.forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const target = document.querySelector(trigger.dataset.showOnClick);
      target.hidden = false;
    });
  });
});
