const isMobile = () => {
  const breakpointSmall = getComputedStyle(document.body).getPropertyValue(
    '--breakpoint-s',
  );
  return window.matchMedia(`(max-width: ${breakpointSmall})`).matches;
};

export default isMobile;
