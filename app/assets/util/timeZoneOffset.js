/**
 * Calculates the timezone offset form GMT as string
 * e.g. GMT+01:00
 *
 * If there is a timezone that has offset minutes,
 * it's displayed accordingly.
 * E.g. GMT+5:45
 *
 * No offset will return +00:00
 *
 * @param {Date} date
 * @returns {String}
 */
const getGMTOffset = (date = new Date()) => {
  const offset = date.getTimezoneOffset();

  // The number of minutes returned by getTimezoneOffset()
  // is positive if the local time zone is behind UTC,
  // and negative if the local time zone is ahead of UTC.
  // See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/getTimezoneOffset
  const sign = offset > 0 ? '-' : '+';

  // Get hours and minutes with leading 0
  const hours = Math.floor(Math.abs(offset / 60))
    .toString()
    .padStart(2, '0');
  const minutes = Math.abs(offset % 60)
    .toString()
    .padStart(2, '0');

  // Return minutes only if they are relevant
  return `${sign + hours}:${minutes}`;
};

export default getGMTOffset;
