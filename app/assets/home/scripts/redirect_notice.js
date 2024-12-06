/**
 * Script for the cookie handling when showing a notice during redirect to an external page
 */

import Cookies from 'js-cookie';
import ready from 'util/ready';

ready(() => {
  const notice = document.querySelector('.redirect-notice');

  if (!notice) {
    return;
  }

  // register event handler to set or remove a cookie to skip the redirect notice
  document
    .getElementById('skip_redirect_notice')
    .addEventListener('change', () => {
      if (document.getElementById('skip_redirect_notice').checked === true) {
        Cookies.set('skip_redirect_notice', 1, { expires: 365 });
      } else {
        // If a user unchecks before the redirect is triggered, remove the cookie again
        Cookies.remove('skip_redirect_notice');
      }
    });
});
