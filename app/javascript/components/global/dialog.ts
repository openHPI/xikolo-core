import ready from '../../util/ready';

const initializeDialog = (dialog: HTMLDialogElement) => {
  const triggerButton = document.querySelector(
    `[aria-controls=${dialog.id}]`,
  ) as HTMLElement;

  if (!triggerButton) return;

  const closeButtons = dialog.querySelectorAll(
    "button[data-behavior='close-dialog']",
  );

  triggerButton.addEventListener('click', (e) => {
    e.preventDefault();
    dialog.showModal();
  });

  closeButtons.forEach((button) =>
    button.addEventListener('click', () => {
      dialog.close();
    }),
  );
};

ready(() => {
  const dialogs = document.querySelectorAll<HTMLDialogElement>(
    'dialog[data-behavior=dialog]',
  );

  dialogs.forEach((dialog) => initializeDialog(dialog));
});

export default initializeDialog;
