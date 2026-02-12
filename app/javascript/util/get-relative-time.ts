/**
 * Helper for inline JS
 * @deprecated
 */

import { DateTime } from 'luxon';
import getLocale from './locale';
declare global {
  interface Window {
    getRelativeTime: (date: Date) => string | null;
  }
}

window.getRelativeTime = (date: Date) => {
  const dateTime = DateTime.fromJSDate(date);
  const locale = getLocale();
  return dateTime.setLocale(locale).toRelative();
};
