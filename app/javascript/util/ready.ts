import { loadTranslations } from '../i18n/i18n';

/**
 * Invoke a function when the DOM is ready and translations are loaded.
 *
 * This fires ONCE per call. For code that needs to run on every
 * Turbo navigation, use turboReady() instead.
 *
 * @param {Function} fn A function to execute when the DOM and translations are ready.
 *
 * @return {void}
 */

const ready = async (fn: () => void) => {
  document.addEventListener(
    'turbo:load',
    async () => {
      await loadTranslations();
      fn();
    },
    { once: true },
  );
};

/**
 * Invoke a function on EVERY Turbo page visit (including initial load).
 * Use this for per-page element initialization that needs to re-run
 * when Turbo replaces the page content.
 *
 * @param {Function} fn A function to execute on each page visit and after failed form submit.
 *
 * @return {void}
 */
export const turboReady = (fn: () => void) => {
  document.addEventListener('turbo:load', async () => {
    await loadTranslations();
    fn();
  });
};

export default ready;
