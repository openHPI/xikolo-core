import { I18n } from 'i18n-js';

// Create the I18n instance
const i18n = new I18n();

export const loadTranslations = async () => {
  const locale = document.documentElement.lang;
  const defaultLocale = document.documentElement.getAttribute(
    'data-default-locale',
  );

  if (!locale || !defaultLocale) return;

  // Configure the I18n instance
  i18n.defaultLocale = defaultLocale;
  i18n.locale = locale;

  // Lazy load translations based on the locale
  const translation = await import(`./translations/${locale}`);
  i18n.store(translation.default);
};

export default i18n;
