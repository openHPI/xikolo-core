import ready from 'util/ready';

const isCollapsed = (element) =>
  element.getAttribute('aria-expanded') === 'false';

/**
 * TODO: XI-5132
 * - use CSS breakpoints
 * - remove window.innerWidth checks
 * - implement responsive layout with CSS media queries
 */
const isMobileView = () => window.innerWidth <= 768;

/*
 * TODO: XI-5132
 * - remove classList manipulation
 * - change CSS to a flex layout
 * - implement media queries for mobile / desktop view
 */
const collapseMainContent = () => {
  const mainContent = document.querySelector('#maincontent');
  const sectionNavSide = document.querySelector('#leftnav');

  if (!mainContent || !sectionNavSide) return;

  mainContent.setAttribute('data-expanded', 'false');
  mainContent.classList.remove('col-md-12');
  mainContent.classList.add('col-md-9');
  mainContent.classList.add('col-md-push-3');

  sectionNavSide.classList.remove('hidden');
};

/*
 * TODO: XI-5132
 * - remove classList manipulation
 */
const expandMainContent = () => {
  const mainContent = document.querySelector('#maincontent');
  const sectionNavSide = document.querySelector('#leftnav');

  if (!mainContent || !sectionNavSide) return;

  mainContent.setAttribute('data-expanded', 'true');
  mainContent.classList.remove('col-md-push-3');
  mainContent.classList.remove('col-md-9');
  mainContent.classList.add('col-md-12');
  mainContent.classList.add('col-md-push-0');

  sectionNavSide.classList.add('hidden');
};

const toggleSectionNavSide = () => {
  const navToggleSide = document.querySelector('#togglenav_horizontal');
  const toggleNavButton = document.querySelector(
    '#togglenav_horizontal .toggle-button span',
  );

  if (isCollapsed(navToggleSide)) {
    navToggleSide.setAttribute('aria-expanded', 'true');
    localStorage.setItem('section_navigation_expanded', 'true');

    collapseMainContent();

    toggleNavButton.classList.remove('icon-arrow-right-double');
    toggleNavButton.classList.add('icon-arrow-left-double');
  } else {
    navToggleSide.setAttribute('aria-expanded', 'false');
    localStorage.setItem('section_navigation_expanded', 'false');

    expandMainContent();

    toggleNavButton.classList.remove('icon-arrow-right-double');
    toggleNavButton.classList.add('icon-arrow-left-double');
  }
};

const toggleSectionNavBottom = () => {
  const navToggleBottom = document.querySelector('#togglenav_vertical');
  const sectionNavSide = document.querySelector('#sectionnav');
  const text = document.querySelector('#togglenav_vertical .toggle-text');
  const icon = document.querySelector(
    '#togglenav_vertical .toggle-button .xi-icon',
  );

  if (isCollapsed(navToggleBottom)) {
    navToggleBottom.setAttribute('aria-expanded', 'true');
    localStorage.setItem('section_navigation_expanded', 'true');

    icon.classList.remove('fa-chevron-down');
    icon.classList.add('fa-chevron-up');

    text.innerHTML = document.querySelector(
      '#togglenav_vertical .toggle-text',
    ).dataset.hideText;

    sectionNavSide.classList.remove('hidden');
  } else {
    navToggleBottom.setAttribute('aria-expanded', 'false');
    localStorage.setItem('section_navigation_expanded', 'false');

    icon.classList.add('fa-chevron-down');
    icon.classList.remove('fa-chevron-up');

    text.innerHTML = document.querySelector(
      '#togglenav_vertical .toggle-text',
    ).dataset.showText;
    sectionNavSide.classList.add('hidden');
  }
};

ready(() => {
  const navToggleSide = document.querySelector('#togglenav_horizontal');
  const navToggleBottom = document.querySelector('#togglenav_vertical');
  const navToggleMainContent = document.querySelector(
    '.course-navbar-toggle.collapsed',
  );

  if (!navToggleSide || !navToggleBottom || !navToggleMainContent) return;

  // Toggle section nav based on user setting, default is expanded
  if (localStorage.getItem('section_navigation_expanded') === 'false') {
    if (isMobileView()) {
      toggleSectionNavBottom();
    } else {
      toggleSectionNavSide();
    }
  }

  navToggleSide.addEventListener('click', () => {
    toggleSectionNavSide();
  });

  navToggleMainContent.addEventListener('click', () => {
    toggleSectionNavSide();
  });

  navToggleBottom.addEventListener('click', () => {
    toggleSectionNavBottom();
  });
});
