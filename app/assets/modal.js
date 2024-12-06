import ready from 'util/ready';

import './modal.scss';

ready(() => {
  /**
   * Send modal dismiss message when a `data-dismiss=modal` thing is clicked
   */
  document.addEventListener('click', (e) => {
    if (!e.target.matches('[data-dismiss=modal]')) return;

    window.parent.postMessage({
      action: 'modal:dismiss',
      detail: e.target.dataset.dismissDetail,
    });
    e.preventDefault();
  });

  /**
   * Send modal dismiss if a script tag has `data-dismiss=modal`.
   * Used to auto close modals e.g. after form submit.
   */
  const el = document.querySelector('script[data-dismiss=modal]');
  if (el) {
    window.parent.postMessage({
      action: 'modal:dismiss',
      detail: el.dataset.dismissDetail,
    });
  }
});
