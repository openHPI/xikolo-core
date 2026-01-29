/**
 * Click on a DOM element to show another
 *
 * The click trigger is specified with the show-on-click data attribute
 * The value of it will specify the target that will be shown
 */

import ready from '../../util/ready';

ready(() => {
  const triggers = document.querySelectorAll('[data-show-on-click]');

  triggers.forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const target = document.querySelector(trigger.dataset.showOnClick);
      target.hidden = false;
    });
  });
});
