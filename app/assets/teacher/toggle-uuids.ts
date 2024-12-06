const toggleUuids = (selector: string) => {
  const uuidElements = document.querySelectorAll('.uuid');
  const toggleButton = document.querySelector(selector);

  if (!uuidElements || !toggleButton) return;

  const hideBtnText = toggleButton.querySelector('#hide') as HTMLElement;
  const showBtnText = toggleButton.querySelector('#show') as HTMLElement;

  toggleButton.addEventListener('click', () => {
    hideBtnText.hidden = !hideBtnText.hidden;
    showBtnText.hidden = !showBtnText.hidden;

    uuidElements.forEach((element) => {
      const el = element as HTMLElement;
      el.hidden = !el.hidden;
    });
  });
};

export default toggleUuids;
