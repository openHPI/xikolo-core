/**
 * Hide a DOM element on form submit
 *
 * Forms with a `data-hide-on-submit` attribute automatically hide the DOM
 * element referenced by the attribute once the form is submitted. Only the
 * first matching DOM node will be hidden.
 *
 * The primary use case is hiding filtered content when submitting forms, until
 * the new filter criteria are applied.
 */
import { turboReady } from '../../util/ready';

document.addEventListener('turbo:before-cache', () => {
  document.querySelectorAll('[data-hide-on-submit]').forEach((el) => {
    const target = document.querySelector(el.dataset.hideOnSubmit);
    if (target) target.hidden = false;
  });
});

turboReady(() => {
  const forms = document.querySelectorAll('[data-hide-on-submit]');

  forms.forEach((form) => {
    form.addEventListener('submit', () => {
      const target = document.querySelector(form.dataset.hideOnSubmit);
      target.hidden = true;
    });
  });
});
