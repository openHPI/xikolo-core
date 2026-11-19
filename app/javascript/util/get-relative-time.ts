/**
 * Helper for relative time formatting.
 * @deprecated
 */

import { DateTime } from 'luxon';
import getLocale from './locale';

const getRelativeTime = (date: Date) => {
  const dateTime = DateTime.fromJSDate(date);
  const locale = getLocale();
  return dateTime.setLocale(locale).toRelative();
};

export default getRelativeTime;
