import { loadTranslations } from '../i18n/i18n';

/**
 * Invoke a function when the DOM is ready and translations are loaded.
 *
 * This fires ONCE per call - on the first turbo:load (with Turbo) or
 * DOMContentLoaded (without Turbo). For code that needs to run on every
 * Turbo navigation, use turboReady() instead.
 *
 * @param {Function} fn A function to execute when the DOM and translations are ready.
 *
 * @return {void}
 */

const loadDomContent = () =>
  new Promise((resolve) => {
    // If DOM is already ready (common after Turbo visits), resolve immediately.
    // This fixes inline JS that runs AFTER turbo:load has fired.
    if (
      document.readyState === 'complete' ||
      document.readyState === 'interactive'
    ) {
      setTimeout(resolve, 0);
      return;
    }

    // DOM not ready yet, wait for the appropriate event
    if (window.Turbo) {
      document.addEventListener('turbo:load', resolve, { once: true });
    } else {
      document.addEventListener('DOMContentLoaded', resolve, { once: true });
    }
  });

const ready = async (fn: () => void) => {
  // Wait for both DOM and translations to be ready
  await Promise.all([loadDomContent(), loadTranslations()]);
  fn();
};

/**
 * Invoke a function on EVERY Turbo page visit (including initial load).
 * Use this for per-page element initialization that needs to re-run
 * when Turbo replaces the page content.
 *
 * Also runs after a failed form submission (e.g. 422): Turbo renders the
 * response but does not fire turbo:load, so without this, anything using
 * turboReady would not re-run and the page can look broken (e.g. markdown
 * editor stays as a plain textarea).
 *
 * @param {Function} fn A function to execute on each page visit and after failed form submit.
 *
 * @return {void}
 */
export const turboReady = (fn: () => void) => {
  const execute = async () => {
    await loadTranslations();
    fn();
  };

  if (window.Turbo) {
    // With Turbo: fire on every turbo:load
    document.addEventListener('turbo:load', execute);
    // Also fire after failed form submit (422 etc.); Turbo does not fire turbo:load then.
    document.addEventListener('turbo:submit-end', (e) => {
      if (e.detail?.success === false) {
        setTimeout(execute, 0);
      }
    });
  } else {
    // Without Turbo: fire once when DOM is ready
    if (
      document.readyState === 'complete' ||
      document.readyState === 'interactive'
    ) {
      execute();
    } else {
      document.addEventListener('DOMContentLoaded', execute, { once: true });
    }
  }
};

export default ready;
