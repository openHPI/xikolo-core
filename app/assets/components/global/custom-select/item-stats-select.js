/**
 * After selecting an option from the tomSelect element,
 * we redirect to the url defined by the option value.
 */

export default function itemStats() {
  const settings = {
    onItemAdd(value) {
      window.location.href = value;
    },
  };

  return settings;
}
