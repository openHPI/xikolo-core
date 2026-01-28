import { I18n } from 'i18n-js';

// Create the I18n instance
const i18n = new I18n();

export const loadTranslations = async () => {
  const locale = document.documentElement.lang;
  const defaultLocale = document.documentElement.dataset.defaultLocale;
  const localeUrl = document.documentElement.dataset.localeUrl;

  if (!locale || !defaultLocale) return;

  // Configure the I18n instance
  i18n.defaultLocale = defaultLocale;
  i18n.locale = locale;

  // Lazy load translations
  if (localeUrl) {
    const response = await fetch(localeUrl);
    const translations = await response.json();
    i18n.store(translations);
  }
};

export default i18n;
