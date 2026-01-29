/**
 * Component for toggling an expandable container
 * Per default, the container is collapsed
 */

import ready from '../../util/ready';

const contentFitsIn = (div) => div.scrollHeight <= div.offsetHeight;

ready(() => {
  const collapsibleElement = document.querySelector('.collapsible-element');
  const collapsibleContainer = document.querySelector('.collapsible-container');
  const buttonContainer = document.querySelector(
    '.collapsible-button-container',
  );

  if (!collapsibleElement || !collapsibleContainer || !buttonContainer) return;

  let ariaExpanded = false;

  buttonContainer.addEventListener('click', (e) => {
    e.preventDefault();
    ariaExpanded = !ariaExpanded;
    collapsibleContainer.setAttribute('aria-expanded', ariaExpanded);
  });

  if (contentFitsIn(collapsibleElement)) {
    ariaExpanded = true;
    collapsibleContainer.setAttribute('aria-expanded', ariaExpanded);
    buttonContainer.classList.add('hidden');
  }

  window.addEventListener('resize', () => {
    // reset expansion for contentFitsIn calculation
    collapsibleContainer.setAttribute('aria-expanded', false);

    if (contentFitsIn(collapsibleElement)) {
      ariaExpanded = true;
      collapsibleContainer.setAttribute('aria-expanded', ariaExpanded);
      buttonContainer.classList.add('hidden');
    } else {
      ariaExpanded = false;
      collapsibleContainer.setAttribute('aria-expanded', ariaExpanded);
      buttonContainer.classList.remove('hidden');
    }
  });
});
