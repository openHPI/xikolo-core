import Cookies from 'js-cookie';
import ready from 'util/ready';

ready(() => {
  // HACK: popover is a Bootstrap component that requires jQuery - jQuery comes from Sprockets assets.
  // eslint-disable-next-line no-undef
  const $ = jQuery;

  const popovers = document.querySelectorAll(
    '[data-behavior="popover-template"]',
  );

  popovers.forEach((popover) => {
    const targetId = popover.dataset.target;
    const popoverTarget = $(`[data-behavior="${targetId}"]`);

    // Add <button> to allowList to render custom template
    // See: https://getbootstrap.com/docs/3.4/javascript/#js-sanitizer
    // This is a copy of the default whiteList so that it is only used for this instance
    const popOverWhiteList = {
      ...{ button: ['type', 'data-popover', 'data-cookie'] },
      ...$.fn.popover.Constructor.DEFAULTS.whiteList,
    };

    popoverTarget
      .popover({
        placement: 'right',
        title: I18n.t('components.popover.title'),
        content: popover.dataset.content,
        trigger: 'manual',
        template: popover.innerHTML,
        whiteList: popOverWhiteList,
        container: 'body',
      })
      .popover('show');

    const closeButton = document.querySelector('[data-popover="close"]');
    if (closeButton) {
      closeButton.addEventListener('click', () => {
        popoverTarget.popover('hide');
      });
    }

    const dismissButton = document.querySelector('[data-popover="dismiss"]');
    if (dismissButton) {
      dismissButton.addEventListener('click', () => {
        popoverTarget.popover('hide');
        Cookies.set(dismissButton.dataset.cookie, true);
      });
    }
  });
});
