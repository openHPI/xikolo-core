import $ from 'jquery';
import './modal.scss';

/**
 * Opens a bootstrap modal with an iframe.
 *
 * Needs to be passed a DOM element containing valid bootstrap
 * modal markup like this:
 *
 *     #my-modal.modal.fade[
 *         tabindex='-1' role='dialog'
 *         aria-hidden='true' aria-labelledby='my-modal-title'
 *     ]
 *       div.modal-dialog role='document'
 *          .modal-content
 *            .modal-header
 *              h3.modal-title#my-modal-title
 *            .modal-frame
 *
 * The IDs for the modal and the modal title can be arbitrarily
 * chosen. The iframe will be inserted into the `.modal-frame`.
 * Title text will be changed in `.modal-title`.
 *
 * @param {HTMLElement} el Node with bootstrap modal markup.
 *
 * @return {void}
 */
export default function modal(el, src) {
  return new Promise((resolve) => {
    const iframe = document.createElement('iframe');
    iframe.src = src;

    // This function will listen for dismiss messages send by the above
    // iframe to the parent window.
    const dismiss = (e) => {
      if (e.source !== iframe.contentWindow) return;

      const { action } = e.data;
      if (action !== 'modal:dismiss') return;

      window.removeEventListener('message', dismiss);
      iframe.remove();

      $(el).modal('hide');

      resolve(e.data);
    };

    window.addEventListener('message', dismiss);

    // Resize iframe on load events
    iframe.addEventListener('load', () => {
      const height =
        iframe.contentWindow.document.querySelector('.wrapper').offsetHeight;
      iframe.style.height = `${height}px`;
    });

    // Clean up modal frame container and add new iframe
    const ct = el.querySelector('.modal-frame');
    ct.childNodes.forEach((e) => e.remove());
    ct.append(iframe);

    $(el).modal();
  });
}
