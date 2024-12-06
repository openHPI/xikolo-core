# frozen_string_literal: true

module Course
  class PopoverPreview < ViewComponent::Preview
    # Requires a text and an id to identify the element in which the popover will
    # be attached to. The element will need a data-behavior attribute with the id as a value.
    #
    # @label Default
    def default
      render_with_template(template: 'course/popover_preview',
        locals: {text: 'This is a very useful hint', target: 'target-useful-hint', cookie: nil})
    end

    # If the cookie_name param is passed in, a button to dismiss the popover is included in the
    # component. On click it adds a cookie to the browser and the component will not
    # appear again.
    #
    # @label with dismiss button
    def with_dismiss_button
      render_with_template(template: 'course/popover_preview',
        locals: {text: 'This is a very useful hint', target: 'target-useful-hint', cookie: 'hide-useful-hint'})
    end
  end
end
