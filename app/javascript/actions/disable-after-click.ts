/**
 * Disable a DOM element after clicking into it
 *
 * Elements with a `data-behavior=-disable-on-click` will get the disabled
 * utility class (i.e. opacity will be decreased and pointer events will be disabled)
 *
 * The primary use case is avoiding multiple clicks to a link or button while
 * its action is being processed.
 *
 */
import ready from '../util/ready';

ready(() => {
  const elements: NodeListOf<HTMLFormElement> = document.querySelectorAll(
    '[data-behavior=disable-after-click]',
  );

  elements.forEach((el) => {
    el.addEventListener('click', () => {
      el.classList.add('disabled');
    });
  });
});
