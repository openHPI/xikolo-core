/**
 * JS logic for Util::RelativeTimeTag component
 */
import { DateTime } from 'luxon';

import ready from '../../util/ready';
import getLocale from '../../util/locale';

ready(() => {
  document
    .querySelectorAll("[data-controller='relative-time']")
    .forEach((el) => {
      const element = el;
      const timeAttribute = element.getAttribute('data-time')!;
      const limitAttribute = element.getAttribute('data-limit')!;
      const locale = getLocale();

      const systemTime = DateTime.now();
      const time = DateTime.fromISO(timeAttribute);
      const limit = DateTime.fromISO(limitAttribute);

      const timeToNow = systemTime.diff(time);
      const limitToNow = systemTime.diff(limit);
      const limitReached =
        Math.abs(timeToNow.toMillis()) > Math.abs(limitToNow.toMillis());

      // If the limit is reached, we print a localized date (e.g. 4/20/2024)
      // Otherwise, it will be a relative representation of this time (e.g. 'in two days')
      if (limitReached) {
        element.textContent = time.setLocale(locale).toLocaleString();
      } else {
        element.textContent = time.setLocale(locale).toRelative();
      }
    });
});

declare global {
  interface Window {
    getRelativeTime: (date: Date) => string | null;
  }
}

/**
 * Helper for inline JS / Sprockets
 * @deprecated
 */
window.getRelativeTime = (date: Date) => {
  const dateTime = DateTime.fromJSDate(date);
  const locale = getLocale();
  return dateTime.setLocale(locale).toRelative();
};
