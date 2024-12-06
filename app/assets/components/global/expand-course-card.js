/**
 * Enables the course card to expand on mouseenter to display more information
 *
 * A partially hidden card in a slider will not expand.
 */

import ready from 'util/ready';

const isPartiallyHidden = (card) => {
  const slider = card.closest('[data-slider-target="content"]');
  if (!slider) return false;

  const sliderPosition = slider.getBoundingClientRect();
  const cardPosition = card.getBoundingClientRect();

  const overflowsRight =
    slider.offsetWidth +
      sliderPosition.left -
      (card.offsetWidth + cardPosition.left) <
    0;
  const overflowsLeft = cardPosition.left - sliderPosition.left < 0;

  return overflowsRight || overflowsLeft;
};

const initializePlaceholder = () => {
  const placeholderCard = document.createElement('div');

  placeholderCard.setAttribute('data-id', 'placeholder-card');
  placeholderCard.addEventListener('mouseleave', () => {
    placeholderCard.innerHTML = '';
  });

  const slider = document.querySelector('[data-slider-target="content"]');
  if (slider) {
    slider.addEventListener('scroll', () => {
      placeholderCard.innerHTML = '';
    });

    // Forward horizontal scrolling motion on the placeholder card to slider
    // If shift key is down, forward also vertical scrolling
    placeholderCard.addEventListener('wheel', (event) => {
      if (event.deltaX !== 0 || event.shiftKey) {
        placeholderCard.innerHTML = '';
        event.preventDefault();
        slider.scroll({ left: slider.scrollLeft + event.deltaX });
      }
    });
  }

  // Reset placeholder content on screen resize to avoid miss-placement
  window.addEventListener('resize', () => {
    placeholderCard.innerHTML = '';
  });

  document.body.appendChild(placeholderCard);
};

const expandCard = (card) => {
  if (isPartiallyHidden(card)) return;
  if (window.matchMedia('(max-width: 576px)').matches) return;

  card.querySelector('img').setAttribute('loading', 'eager');
  const cloneCard = card.cloneNode(true);

  const placeholderCard = document.querySelector(
    "[data-id='placeholder-card']",
  );

  placeholderCard.appendChild(cloneCard);

  const cardProperties = card.getBoundingClientRect();
  cloneCard.classList.add('course-card--expanded');
  cloneCard.style.width = `${cardProperties.width}px`;
  cloneCard.style.height = `${cardProperties.height}px`;
  cloneCard.style.top = `${cardProperties.top + window.scrollY}px`;
  cloneCard.style.left = `${cardProperties.left}px`;
};

const addExpandableBehavior = (card) => {
  card.addEventListener('mouseenter', () => {
    expandCard(card);
  });
  card.setAttribute('data-behavior', 'expandable-enabled');
};

const enableExpandableCourseCards = () => {
  const expandableCourseCards = document.querySelectorAll(
    "[data-behavior='expandable']",
  );

  if (!expandableCourseCards.length) return;

  initializePlaceholder();

  expandableCourseCards.forEach((card) => {
    addExpandableBehavior(card);
  });
};

ready(() => {
  enableExpandableCourseCards();

  // A "load more" button adds new cards where the behavior still needs to be added
  // Exclude cards with expansion already added
  document.addEventListener('load-more:course-cards', () => {
    const addedCards = document.querySelectorAll(
      "[data-behavior='expandable']",
    );

    addedCards.forEach((card) => {
      addExpandableBehavior(card);
    });
  });
});
