# frozen_string_literal: true

module Util
  class CustomSelectPreview < ViewComponent::Preview
    # To transform regular select elements into customized and enhanced select boxes add the
    # "data-behavior=custom-select" attribute to the select element (in simple forms these
    # are usually 'f.input').
    # For a multiple selection add the "multiple" attribute
    #
    # @label Multiple select
    def multiple
      render_with_template(
        template: 'util/custom_select/custom_select_multiple'
      )
    end

    # More advanced settings like remote search, preload options, grouped options
    # or allowing the user to create new items are also available.
    def advanced_options
      render_with_template(
        template: 'util/custom_select/custom_select'
      )
    end
  end
end
