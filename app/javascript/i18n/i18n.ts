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
      i18n.store(await fetchTranslations(localeUrl));
    }
  })();

  return translationsPromise;
};

const fetchTranslations = async (
  url: string,
): Promise<Record<string, unknown>> => {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(
      `Failed to fetch translations (${response.status}): ${response.statusText}`,
    );
  }

  return response.json();
};

export default i18n;
