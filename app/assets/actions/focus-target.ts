/**
 * Sprinkle for scrolling and focusing an element.
 * It also sets the focus on the scroll target.
 *
 * Optionally, a different element can be focused.
 */

import ready from '../util/ready';

ready(() => {
  const scrollTrigger = document.querySelector("[data-id='scroll-trigger']");
  const scrollTarget = document.querySelector("[data-id='scroll-target']");
  const focusTarget =
    document.querySelector("[data-id='focus-target']") || scrollTarget;

  if (!scrollTrigger || !scrollTarget) return;

  scrollTrigger.addEventListener('click', (e) => {
    e.preventDefault();

    scrollTarget.scrollIntoView({ block: 'center' });

    if (focusTarget instanceof HTMLElement) {
      focusTarget.focus();
    }
  });
});
