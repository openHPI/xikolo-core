/**
 * Show a DOM element on form submit
 *
 * Forms with a `data-show-on-submit` attribute automatically reveal the DOM
 * element referenced by the attribute once the form is submitted. Only the
 * first matching DOM node will be revealed.
 *
 * The primary use case is showing a loading indicator when submitting forms,
 * e.g. with filter criteria.
 */
import ready from 'util/ready';

ready(() => {
  const forms = document.querySelectorAll('[data-show-on-submit]');

  forms.forEach((form) => {
    form.addEventListener('submit', () => {
      const target = document.querySelector(form.dataset.showOnSubmit);
      target.hidden = false;
    });
  });
});
