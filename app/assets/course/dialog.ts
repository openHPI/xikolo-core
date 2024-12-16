import ready from '../util/ready';

const initializeDialog = (dialog: HTMLDialogElement) => {
  const triggerButton = document.querySelector(
    `[aria-controls=${dialog.id}]`,
  ) as HTMLElement;

  if (!triggerButton) return;

  const closeButton = dialog.querySelector(
    "button[type='button']",
  ) as HTMLButtonElement;
  const confirmCheckbox = dialog.querySelector(
    "input[type='checkbox']",
  ) as HTMLInputElement;
  const confirmButton = dialog.querySelector(
    "input[type='submit']",
  ) as HTMLButtonElement;

  triggerButton.addEventListener('click', (e) => {
    e.preventDefault();
    dialog.showModal();
  });

  closeButton.addEventListener('click', () => {
    dialog.close();
  });

  confirmCheckbox.addEventListener('change', () => {
    if (confirmCheckbox.checked) {
      confirmButton.removeAttribute('disabled');
    } else {
      confirmButton.setAttribute('disabled', 'true');
    }
  });
};

ready(() => {
  const dialogs = document.querySelectorAll<HTMLDialogElement>(
    'dialog[data-behavior=enrollment-dialog]',
  );

  dialogs.forEach((dialog) => initializeDialog(dialog));
});

export default initializeDialog;
