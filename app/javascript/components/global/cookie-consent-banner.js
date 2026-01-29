import ready from '../../util/ready';

ready(() => {
  const banner = document.querySelector('.cookie-consent-banner');

  if (!banner) return;

  const closeButton = banner.querySelector("[data-behavior='hide']");

  closeButton.addEventListener('click', () => {
    banner.classList.add('hidden');
  });
});
