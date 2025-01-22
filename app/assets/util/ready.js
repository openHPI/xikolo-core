import { loadTranslations } from '../i18n/i18n';

/**
 * Invoke a function when the DOM is ready and translations are loaded.
 *
 * @param {Function} fn A function to execute when the DOM and translations are ready.
 *
 * @return {void}
 */

const loadDomContent = new Promise((resolve) => {
  if (
    document.readyState === 'complete' ||
    document.readyState === 'interactive'
  ) {
    setTimeout(resolve, 0);
  } else {
    document.addEventListener('DOMContentLoaded', resolve);
  }
});

const ready = async (fn) => {
  // Wait for both DOM and translations to be ready
  await Promise.all([loadDomContent, loadTranslations()]);
  fn();
};

export default ready;
