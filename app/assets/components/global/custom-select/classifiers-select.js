import fetch from 'util/fetch';
import I18n from 'i18n/i18n';

export default function loadClassifiers(element) {
  const { locale, defaultLocale } = I18n;

  const settings = {
    valueField: 'id',
    async load(query, callback) {
      try {
        const url = `/api/v2/classifiers?q=${encodeURIComponent(
          query,
        )}&cluster=${element.dataset.cluster}`;
        const response = await fetch(url);
        const json = await response.json();

        const result = json.classifiers.map((item) => ({
          id: item.title,
          text: item.translations[locale] || item.translations[defaultLocale],
        }));
        callback(result);
      } catch (error) {
        console.error('An error occurred while loading:', error);
        callback();
      }
    },
  };

  return settings;
}
