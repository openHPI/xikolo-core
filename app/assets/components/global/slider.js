/**
 * JS controller for Global::Slider
 *
 * The buttons will trigger either a scroll left or right of the content
 *
 * The observer hides the these button depending on
 * if the first and last element are fully visible (no further scrolling possible)
 * In an intermediate position, both buttons are displayed.
 *
 */
import ready from 'util/ready';

ready(() => {
  const sliderComponents = document.querySelectorAll(
    "[data-controller~='slider']",
  );

  if (!sliderComponents) return;

  sliderComponents.forEach((slider) => {
    const buttonLeft = slider.querySelector(
      "[data-slider-target='scroll-button-left']",
    );
    const buttonRight = slider.querySelector(
      "[data-slider-target='scroll-button-right']",
    );
    let content = slider.querySelector("[data-slider-target='content']");

    // Ensure to scroll to a point where scroll-snap-align behaves the same across browsers
    const getScrollDistance = () => {
      if (!content.clientWidth) {
        //  It could be null on page load if the slider is empty. At this point, however,
        //  the target observer has been reached, meaning that the slider has been filled with content.
        content = slider.querySelector("[data-slider-target='content']");
      }
      return content.clientWidth - buttonRight.clientWidth * 2;
    };

    buttonRight.addEventListener('click', () => {
      content.scrollBy({ left: getScrollDistance(), behavior: 'smooth' });
    });

    buttonLeft.addEventListener('click', () => {
      content.scrollBy({ left: -getScrollDistance(), behavior: 'smooth' });
    });

    // Set up observer
    const intersectorLeft = content.querySelector(
      "[data-slider-target='intersector-left']",
    );
    const intersectorRight = content.querySelector(
      "[data-slider-target='intersector-right']",
    );

    const handleVisibility = (element, hideElement) => {
      if (hideElement) {
        element.setAttribute('hidden', 'true');
      } else {
        element.removeAttribute('hidden');
      }
    };

    const handler = (changes) => {
      changes.forEach((change) => {
        // Hide scroll left button if first item is in view
        if (change.target === intersectorLeft) {
          handleVisibility(buttonLeft, change.isIntersecting);
        }
        // Hide scroll right button if last item is in view
        if (change.target === intersectorRight) {
          handleVisibility(buttonRight, change.isIntersecting);
        }
      });
    };

    const observer = new IntersectionObserver(handler, {
      threshold: 1, // Intersection is full width
      rootMargin: '100% 0% 100% 0%', // Only observe x-axis
    });

    observer.observe(intersectorLeft);
    observer.observe(intersectorRight);
  });
});
