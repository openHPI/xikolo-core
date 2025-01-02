import swal from './swal';

/**
 * Handle errors
 *
 * Can be used to communicate unexpected platform behavior
 * by logging the error and displaying a customizable message.
 *
 * Users can also be informed of false behavior with a message.
 *
 * @param message Text users are presented with in a popup (optional)
 * @param error Error that is logged on the console (optional)
 * @param showMessage Show user facing error message (default is true)
 */
const handleError = (message?: string, error?: unknown, showMessage = true) => {
  if (showMessage) {
    swal.fire({
      title: message || I18n.t('errors.server.generic_message'),
      icon: error ? 'error' : 'info',
      showCancelButton: false,
      buttonsStyling: false,
      focusConfirm: true,
      heightAuto: false,
    });
  }

  if (error) {
    console.error(error);
  }
};

export default handleError;
