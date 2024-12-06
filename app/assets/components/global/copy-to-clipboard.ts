/**
 * Copy to clipboard
 *
 * This script allows the user to copy text to the clipboard.
 *
 * Usage:
 * Add data-behavior='copy-to-clipboard' to the element that should trigger the copy action.
 * Add data-text='value' to the element containing the value to be copied.
 *
 */

import handleError from '../../util/error';
import ready from '../../util/ready';

ready(() => {
  document
    .querySelectorAll("[data-behavior='copy-to-clipboard']")
    .forEach((element) => {
      element.addEventListener('click', async () => {
        try {
          const value = element.getAttribute('data-text');

          if (!value) throw new Error('No data-text attribute found');

          await navigator.clipboard.writeText(value);
        } catch (e) {
          handleError(undefined, e);
        }
      });
    });
});
