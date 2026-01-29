import ready from '../../util/ready';

ready(() => {
  const countrySelect = document.getElementById(
    'xikolo_account_user_country',
  ) as HTMLSelectElement;
  const stateWrapper = document.getElementById(
    'state-field-wrapper',
  ) as HTMLElement;
  const stateSelect = document.getElementById(
    'state-select',
  ) as HTMLSelectElement;

  if (!countrySelect || !stateWrapper || !stateSelect) return;

  function toggleStateField(country: string): void {
    if (country === 'DE') {
      stateWrapper.removeAttribute('hidden');
    } else {
      stateWrapper.setAttribute('hidden', 'true');
    }
  }

  toggleStateField(countrySelect.value);

  countrySelect.addEventListener('change', (e: Event) => {
    const target = e.target as HTMLSelectElement;
    toggleStateField(target.value);
  });
});
