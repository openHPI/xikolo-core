/**
 * Form autosubmit
 *
 * Forms with a `data-autosubmit` attribute are automatically submitted
 * when the page is fully loaded. Only the first matching form in DOM
 * node order is submitted.
 *
 * A warning will be emitted in non-production environments if multiple
 * forms are marked to be autosubmitted.
 */
import ready from 'util/ready';

ready(() => {
  const forms = document.querySelectorAll('form[data-autosubmit]');

  if (__MODE__ !== 'production' && forms.length > 1) {
    console.warn(
      'Multiple form[data-autosubmit] found. Only first will be submitted in production',
    );
  }

  if (forms.length > 0) {
    const form = forms[0];
    form.submit();
  }
});
