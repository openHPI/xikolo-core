import { I18n } from 'i18n-js';

const i18n = new I18n();

// Cache the fetch promise so translations are loaded exactly once per locale,
// even when multiple turboReady callbacks invoke loadTranslations concurrently.
let cachedUrl: string | undefined;
let translationsPromise: Promise<void> | undefined;

export const loadTranslations = (): Promise<void> => {
  const localeUrl = document.documentElement.dataset.localeUrl;

  if (translationsPromise && cachedUrl === localeUrl) {
    return translationsPromise;
  }

  cachedUrl = localeUrl;

  translationsPromise = (async () => {
    const locale = document.documentElement.lang;
    const defaultLocale = document.documentElement.dataset.defaultLocale;

    if (!locale || !defaultLocale) return;

    i18n.defaultLocale = defaultLocale;
    i18n.locale = locale;

    if (localeUrl) {
      const response = await fetch(localeUrl);
      const translations = await response.json();
      i18n.store(translations);
    }
  })();

  return translationsPromise;
};

export default i18n;
