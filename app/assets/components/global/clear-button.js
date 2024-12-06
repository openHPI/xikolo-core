/**
 * Clear button for filter bar text search
 *
 * By clicking the button with the data-id='clear-button',
 * it resets the target input.
 * The target is specified via the value of 'data-clear-target'.
 *
 * After that, the closest form will be submitted.
 */

import ready from 'util/ready';

ready(() => {
  const trigger = document.querySelector("[data-id='clear-button']");

  if (!trigger) return;

  trigger.addEventListener('click', () => {
    const target = document.querySelector(trigger.dataset.clearTarget);
    target.value = '';

    const form = target.closest('form');
    form.requestSubmit();
  });
});
