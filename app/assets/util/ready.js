/**
 * Invoke a function when the DOM is ready.
 *
 * @param {Function} fn A function to execute when the DOM is ready.
 *
 * @return {void}
 */
export default function ready(fn) {
  if (
    document.readyState === 'complete' ||
    document.readyState === 'interactive'
  ) {
    setTimeout(fn, 0);
  } else {
    document.addEventListener('DOMContentLoaded', fn);
  }
}
