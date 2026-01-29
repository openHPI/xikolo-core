/**
 * Form autosubmit
 *
 * Forms with a `data-autosubmit` attribute are automatically submitted
 * when the page is fully loaded. Only the first matching form in DOM
 * node order is submitted.
 */
import ready from '../../util/ready';

ready(() => {
  const forms = document.querySelectorAll('form[data-autosubmit]');

  if (forms.length > 0) {
    const form = forms[0];
    form.submit();
  }
});
