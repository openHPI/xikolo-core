import ready from '../../util/ready';

ready(() => {
  const navigationLogo = document.querySelector(
    "[data-id='desktop-navigation-logo']",
  );
  const headHeroLogo = document.querySelector("[data-id='head-hero-image']");

  if (!navigationLogo || !headHeroLogo) return;

  const handler = (changes) => {
    changes.forEach((change) => {
      if (change.isIntersecting) {
        navigationLogo.dataset.state = 'unobtrusive';
      } else {
        delete navigationLogo.dataset.state;
      }
    });
  };

  const observer = new IntersectionObserver(handler, {
    threshold: 0.1,
    rootMargin: '-50px 0px 0px 0px', // margin-top is height of navigation
  });

  observer.observe(headHeroLogo);
});
