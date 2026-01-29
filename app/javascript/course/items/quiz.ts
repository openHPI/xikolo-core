/**
 * Navigate to the selected submission
 */

import ready from '../../util/ready';

ready(() => {
  const submissionsSelect = document.querySelector(
    "[data-behavior='navigate-to-submission']",
  );

  if (submissionsSelect) {
    submissionsSelect.addEventListener('change', (event: Event) => {
      const target = event.target as HTMLInputElement;
      const newURL = target.value;
      window.location.replace(newURL);
    });
  }
});
