import fetch from '../../../util/fetch';
import I18n from '../../../i18n/i18n';
import handleError from '../../../util/error';

export default function loadClassifiers(element) {
  const { locale, defaultLocale } = I18n;

  return {
    valueField: 'id',
    async load(query, callback) {
      try {
        const url = `/admin/find_classifiers?q=${encodeURIComponent(
          query,
        )}&cluster=${element.dataset.cluster}`;
        const response = await fetch(url);
        const json = await response.json();

        const result = json.map((item) => ({
          id: item.title,
          text: item.translations[locale] || item.translations[defaultLocale],
        }));
        callback(result);
      } catch (error) {
        handleError('An error occurred while loading:', error);
        callback();
      }
    },
  };
}
