import fetch from 'util/fetch';

/**
 * Basic TomSelect settings
 */
export function getBasic() {
  const settings = {
    // The max number of options to display in the dropdown.
    maxOptions: 150,
    // The name of the option group property that serves as its unique identifier.
    optgroupValueField: 'group',
    // The name of the property to group items by.
    optgroupField: 'group',
    // All optgroups will be displayed in the same order as they were added.
    lockOptgroupOrder: true,
    closeAfterSelect: true,
    render: {
      no_results: (data, escape) =>
        // Displayed when no options are found matching a user's search.
        `<div class="no-results">${I18n.t(
          'components.custom_select.no_results',
          { input: escape(data.input) },
        )}</div>`,
      loading: () =>
        // Renders a message to communicate to users that more results are being loaded
        `<div class="no-results">${I18n.t(
          'components.custom_select.loading',
        )}</div>`,
    },
    plugins: {
      clear_button: {
        title: I18n.t('components.custom_select.clear_button'),
      },
    },
  };
  return settings;
}

/**
 * Multiple select advanced settings
 *
 * Adds a plugin to enable one-click removal of each item.
 *
 */
export function getMultipleSelect() {
  const settings = {
    plugins: {
      ...getBasic().plugins,
      remove_button: {
        title: I18n.t('components.custom_select.remove_item'),
      },
    },
  };
  return settings;
}

/**
 * Remote Load Settings
 *
 * It fetches the data from the endpoint specified with the [data-auto-completion-url] attribute.
 * Results will be filtered by the user input (query).
 * If is set to be sorted by groups of options (data items have the 'group' property), it creates
 * the group labels.
 *
 */
export function getRemoteLoad(element) {
  const settings = {
    // The name of the property to use as the value when an item is selected.
    valueField: 'id',
    // The number of milliseconds to wait before requesting options from the server.
    loadThrottle: 500,

    async load(query, callback) {
      const url = new URL(element.dataset.autoCompletionUrl, window.location);
      url.searchParams.set('q', query);

      try {
        const response = await fetch(url);
        const json = await response.json();

        json.forEach((item) => {
          // Creates option group if not already done
          if ('group' in item && !(item.group in this.optgroups)) {
            this.addOptionGroup(item.group, { label: item.group });
          }
        });

        callback(json);
      } catch (error) {
        console.error('An error occurred while loading:', error);
        callback();
      }
    },
  };
  return settings;
}

/**
 * Delayed Load Settings
 *
 * load() will not be called until the user has not typed up to 3 characters.
 * It creates custom templates to render when results are loading or when
 * waiting for user's input.
 *
 */
export function getDelayedLoad() {
  const settings = {
    // Define minimum input length to start loading options ( > 2 characters)
    shouldLoad(query) {
      // Clear results when not loading
      if (query.length <= 2) {
        this.clearOptions();
        this.clearOptionGroups();
        // Clear all optgroup labels
        document
          .querySelectorAll(`#${this.inputId}-ts-dropdown [data-group]`)
          .forEach((group) => group.remove());
      }
      return query.length > 2;
    },

    render: {
      ...getBasic().render,
      // Renders when shouldLoad() callback returns false (i.e. when the user input does not exceed 3 characters)
      not_loading: (data, escape) =>
        `<div class="no-results">${I18n.t(
          'components.custom_select.not_loading',
          { num: 3 - escape(data.input).length },
        )}</div>`,
    },
  };
  return settings;
}

/**
 * Preload Settings
 *
 * The load function will be called upon control focus.
 *
 */
export const preload = {
  preload: 'focus',
};

/**
 * Create Options Settings
 *
 * User is allowed to create new items that aren't in the initial list of options.
 * It creates a template to render when the user input can be added as a new option.
 *
 */
export function getCreateOptions() {
  const settings = {
    // The name of the property to use as the value when an item is selected.
    valueField: 'id',
    create: (input, callback) => {
      callback({
        id: input,
        text: `${input} ${I18n.t('components.custom_select.new')}`,
      });
      return true;
    },
    // Only allow creation of unique options (case-sensitive)
    createFilter(input) {
      const inputLowerCase = input.toLowerCase();
      return !(inputLowerCase in this.options);
    },
    render: {
      ...getBasic().render,
      option_create: (data, escape) =>
        `<div class="create">${I18n.t(
          'components.custom_select.option_create',
          { input: escape(data.input) },
        )}</div>`,
    },
  };
  return settings;
}

/**
 * Prefill select box
 *
 * Use data-prefix attribute.
 *
 */
export function getPrefill(element) {
  const settings = {
    onFocus() {
      if (!this.isFull()) {
        const { prefix } = element.dataset;
        this.setTextboxValue(prefix);
        this.load(prefix);
      }
    },
  };
  return settings;
}
