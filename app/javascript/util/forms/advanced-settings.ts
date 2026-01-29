/**
 * This file is used to toggle the visibility of the advanced settings
 * section in a form.
 * It's used in the `application_helper.rb` file in `advanced_settings`.
 */

import ready from '../ready';

ready(() => {
  const advancedSettingsButtons: NodeListOf<HTMLButtonElement> =
    document.querySelectorAll('[data-behavior=toggle-visibility]');

  advancedSettingsButtons.forEach((button) => {
    const target = document.getElementById(
      button.dataset.toggleVisibility!,
    ) as HTMLElement;
    const onText = button.getAttribute('data-toggle-text-on');
    const offText = button.getAttribute('data-toggle-text-off');

    target.hidden = true;

    button.addEventListener('click', () => {
      const btn = button as HTMLButtonElement;

      if (target.hidden) {
        target.hidden = false;
        btn.textContent = offText;
      } else {
        target.hidden = true;
        btn.textContent = onText;
      }
    });
  });
});
