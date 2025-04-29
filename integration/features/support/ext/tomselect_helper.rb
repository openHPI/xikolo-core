# frozen_string_literal: true

module TomSelectHelper
  # A helper for Capyabara tests that need to set values from a tom-select input.
  #
  # @value (string): Text from option to select
  # @from (string): Label from tom-select input
  # @css (string): Instead of @from, the selector from the input's container
  # can be used. Defaults to ".form".
  # @search (boolean|string): Input the user types for searching. If true but not
  # specified with a string, it defaults to @value.
  # @clear (boolean): If true, clears any selected item before performing the search.

  def tom_select(value, from: nil, css: nil, search: false, clear: false)
    if from
      label = find(:label, text: from)
      container = label.find(:xpath, '..')
    else
      container = find(css || 'form')
    end

    within(container) do
      if clear
        find('.ts-control .clear-button', visible: :all).click
      end
      input = find('.ts-control input')
      input.click

      if search.is_a? String
        input.send_keys(search)
      elsif search
        input.send_keys(value)
      end
    end
    # Ensure all options are loaded
    container.has_no_content?('Searching...') if search
    find('.ts-dropdown .ts-dropdown-content [data-selectable]', text: /#{Regexp.quote(value)}/i).click
    # Ensure dropdown closes
    page.send_keys(:escape)
  end
end

Gurke.world.include(TomSelectHelper)
