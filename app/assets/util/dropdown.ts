import initDropdowns from '../components/global/dropdown';

/**
 * Adapter for attaching Global::ActionsDropdown
 */

const initDropdownsOnSelector = (scope: HTMLElement) => {
  const dropdowns = scope.querySelectorAll("[data-behaviour='dropdown']");
  initDropdowns(dropdowns);
};

export default initDropdownsOnSelector;
