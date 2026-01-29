/**
 * Show loading overlay
 */
const showLoading = () => {
  const loadingDimmer = document.querySelector(
    '#loading-dimmer',
  ) as HTMLElement;
  loadingDimmer.hidden = false;
};

/**
 * Hide loading overlay
 */
const hideLoading = () => {
  const loadingDimmer = document.querySelector(
    '#loading-dimmer',
  ) as HTMLElement;
  loadingDimmer.hidden = true;
};

export { showLoading, hideLoading };
