import { DateTime } from 'luxon';
import flatpickr from 'flatpickr';
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import { de } from 'flatpickr/dist/l10n';
import ready from 'util/ready';
import getGMTOffset from '../../util/timeZoneOffset';
import CustomButtonsPlugin from './flatpickr/customButtonsPlugin';
import getLocale from '../../util/locale';

/**
 * Parses user input to a JavaScript Date Object
 * User input must be ISO format.
 * See supported variations here: https://moment.github.io/luxon/#/parsing?id=iso-8601
 *
 * There is a bug in flatpickr with dateFormat 'Z'
 * So we need to correct with the time zone offset.
 *
 * https://github.com/flatpickr/flatpickr/issues/2368#issue-775640511
 *
 * @param {string} dateStr
 * @returns Date
 */
const parseDate = (dateStr) => {
  const offset = new Date(dateStr).getTimezoneOffset();
  return DateTime.fromISO(dateStr).plus({ minutes: offset }).toJSDate();
};

/**
 * Formats a JavaScript Date Object to a string
 * represented in ISO format in UTC time
 * @param {Date} date
 * @returns string
 */
const formatDate = (date) =>
  DateTime.fromJSDate(date).toFormat("yyyy-LL-dd'T'HH:mm:ss'Z'");

ready(() => {
  document
    .querySelectorAll('[data-behaviour~=datepicker]')
    .forEach((datepicker) => {
      const config = {
        enableTime: true,
        dateFormat: 'Z',
        locale: getLocale(),
        allowInput: true,
        time_24hr: true,
        plugins: [new CustomButtonsPlugin()],
      };

      if (datepicker.dataset.localdate) {
        const timeZoneOffset = getGMTOffset();

        config.altInput = true;
        config.allowInput = false;
        config.altFormat = `Y-m-d, H:i \\(\\G\\M\\T\\${timeZoneOffset}\\)`;
      } else {
        config.parseDate = parseDate;
        config.formatDate = formatDate;
        config.onReady = (_, __, instance) => {
          if (
            !instance.input.placeholder &&
            datepicker.dataset.birthday !== 'true'
          ) {
            instance.input.placeholder = 'YYYY-MM-DDThh:mm:ssZ';
          }
        };
      }
      if (datepicker.dataset.birthday) {
        const formatDate = (date) =>
          DateTime.fromJSDate(date).toFormat('yyyy-LL-dd');

        config.enableTime = false;
        config.time_24hr = false;
        config.plugins = false;
        config.dateFormat = 'd-m-Y';
        config.altFormat = 'd-m-Y';
        config.allowInput = false;
        config.formatDate = formatDate;
      }
      flatpickr(datepicker, config);
    });
});
