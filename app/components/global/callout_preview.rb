# frozen_string_literal: true

module Global
  class CalloutPreview < ViewComponent::Preview
    include ActionView::Helpers::UrlHelper

    # @!group Types
    def default
      render Global::Callout.new(
        'This is the default callout component'
      )
    end

    def warning
      render Global::Callout.new(
        'This is the warning callout component',
        type: :warning
      )
    end

    def error
      render Global::Callout.new(
        'This is the error callout component',
        type: :error
      )
    end

    def sucess
      render Global::Callout.new(
        'This is the success callout component',
        type: :success
      )
    end

    # @!endgroup

    # @!group Advanced examples

    def with_title
      render Global::Callout.new(
        "A title can help you emphasize the callout message and catch the user's attention",
        title: 'Did you know you can use a title?'
      )
    end

    def warning_with_title
      render Global::Callout.new(
        'Any of the previous types can also have a title',
        type: :warning,
        title: 'Warning callout with title'
      )
    end

    def with_custom_icon
      render Global::Callout.new(
        'The default icons can also be overwritten with a custom icon (component) instance',
        type: :warning,
        icon: Global::FaIcon.new('cloud-arrow-up', style: :solid)
      )
    end

    def with_action
      render Global::Callout.new(
        'You can also add additional content like links or buttons using a slot.
        For a call to action styled as a button we recommend using the following style:'
      ) do
        link_to 'Click here', '/', class: 'btn btn-outline btn-default btn-xs'
      end
    end

    # @!endgroup
  end
end
