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
  const els = document.querySelectorAll('form[data-autosubmit]');

  if (__MODE__ !== 'production' && els.length > 1) {
    // eslint-disable-next-line no-console
    console.warn(
      'Multiple form[data-autosubmit] found. Only first will be submitted in production',
    );
  }

  if (els.length > 0) {
    els[0].submit();
  }
});
