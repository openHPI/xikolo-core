/**
 * Helpdesk button component
 *
 * This avoids overlapping of the button with the version number in the footer.
 *
 * When we refactor the jQuery code from app/assets/javascripts/helpdesk.js,
 * it should go here.
 */

import ready from 'util/ready';

ready(() => {
  const helpdeskButton = document.querySelector('#helpdesk-button');

  if (!helpdeskButton) return;

  const element = document.querySelector('[data-id="footer-copyright"]');

  const handler = (changes) => {
    changes.forEach((change) => {
      if (change.isIntersecting) {
        helpdeskButton.classList.add('helpdesk-button--bottom-reached');
      } else {
        helpdeskButton.classList.remove('helpdesk-button--bottom-reached');
      }
    });
  };

  const observer = new IntersectionObserver(handler, {
    threshold: 1,
  });

  observer.observe(element);
});
