export const isScreenSizeSmall = () => {
  const breakpointSmall = getComputedStyle(document.body).getPropertyValue(
    '--breakpoint-s',
  );
  return window.matchMedia(`(max-width: ${breakpointSmall})`).matches;
};

export const isScreenSizeSM = () => {
  const breakpointSM = getComputedStyle(document.body).getPropertyValue(
    '--breakpoint-sm',
  );
  return window.matchMedia(`(max-width: ${breakpointSM})`).matches;
};
