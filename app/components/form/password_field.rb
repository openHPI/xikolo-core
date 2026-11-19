# frozen_string_literal: true

module Form
  # A password input with a button to toggle the visibility of its value.
  class PasswordField < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] the form the field belongs to
    # @param attribute [Symbol] the attribute to build the field for
    # @param options [Hash] additional options for the password field, e.g.
    #   `placeholder` or `autocomplete`
    def initialize(form, attribute, **options)
      @form = form
      @attribute = attribute
      @options = options
    end
  end
end
