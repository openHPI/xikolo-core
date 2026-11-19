/**
 * Script for the cookie handling when showing a notice during redirect to an external page
 */

import { turboReady } from '../../util/ready';

turboReady(async () => {
  const checkbox = document.getElementById('skip_redirect_notice');

  if (!checkbox) return;

  const { default: Cookies } = await import('js-cookie');

  // register event handler to set or remove a cookie to skip the redirect notice
  checkbox.addEventListener('change', () => {
    if (checkbox.checked) {
      Cookies.set('skip_redirect_notice', 1, { expires: 365 });
    } else {
      // If a user unchecks before the redirect is triggered, remove the cookie again
      Cookies.remove('skip_redirect_notice');
    }
  });
});
