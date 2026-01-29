/* eslint-disable no-undef */

// We cannot import $ because the popover plugin
// expects it to be globally available.
import 'jquery';
import Cookies from 'js-cookie';
import ready from '../../util/ready';
import I18n from '../../i18n/i18n';
import { isScreenSizeSM } from '../../util/media-query';

ready(() => {
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

    popoverTarget.popover({
      placement: isScreenSizeSM() ? 'top' : 'right',
      title: I18n.t('components.popover.title'),
      content: popover.dataset.content,
      trigger: 'manual',
      template: popover.innerHTML,
      whiteList: popOverWhiteList,
      container: 'body',
    });

    if (targetId.includes('--mobile') === isScreenSizeSM()) {
      popoverTarget.popover('show');
    }

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
