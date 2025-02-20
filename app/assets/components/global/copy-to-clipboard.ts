/**
 * Copy to clipboard
 *
 * This script allows the user to copy text to the clipboard.
 *
 * Usage:
 * Add data-behavior='copy-to-clipboard' to the element that should trigger the copy action.
 * Add data-text='value' to the element containing the value to be copied.
 *
 * This code is also used for the component Global::CopyToClipboard
 *
 */

import handleError from '../../util/error';
import ready from '../../util/ready';
import I18n from '../../i18n/i18n';

const showSuccessMessage = (element: Element) => {
  const tooltip = element.querySelector<HTMLElement>(
    "[data-behavior='clipboard-tooltip']",
  );
  if (!tooltip) return;

  const originalText = tooltip.textContent;
  if (originalText != I18n.t('components.clipboard.copied')) {
    tooltip.textContent = I18n.t('components.clipboard.copied');
    tooltip.style.display = 'block';

    // Restore original text after 1 second
    setTimeout(() => {
      tooltip.textContent = originalText;
      tooltip.style.removeProperty('display');
    }, 1000);
  }
};

ready(() => {
  document
    .querySelectorAll("[data-behavior='copy-to-clipboard']")
    .forEach((element) => {
      element.addEventListener('click', async () => {
        try {
          const value = element.getAttribute('data-text');

          if (!value) throw new Error('No data-text attribute found');

          await navigator.clipboard.writeText(value);
          showSuccessMessage(element);
        } catch (e) {
          handleError(undefined, e);
        }
      });
    });
});
