# frozen_string_literal: true

module Global
  class ActionsDropdownPreview < ViewComponent::Preview
    # @!group

    # Links and buttons can be passed as blocks
    # to define the dropdown menu items.
    #
    # @label Default
    def default
      render Global::ActionsDropdown.new do |c|
        c.with_action { '<a href=# class="bs-a">Edit</a>'.html_safe }
        c.with_action { '<a href=# class="bs-a">Show</a>'.html_safe }
        c.with_action { '<button href=#>Copy ID</button>'.html_safe }
      end
    end

    def aligned_right
      render Global::ActionsDropdown.new(menu_side: 'right') do |c|
        c.with_action { '<a href=# class="bs-a">Edit</a>'.html_safe }
        c.with_action { '<a href=# class="bs-a">Show</a>'.html_safe }
      end
    end

    # "Destructive" actions can be passed as blocks.
    # The error color scheme will be used.
    #
    # @label With destructive action
    def with_destructive_action
      render Global::ActionsDropdown.new do |c|
        c.with_action { '<a href=# class="bs-a">Edit</a>'.html_safe }
        c.with_destructive_action { '<a href=# class="bs-a">Delete</a>'.html_safe }
      end
    end

    # You can include an icon, it will be placed to the right side
    #
    # @label With icon
    def with_icon
      render Global::ActionsDropdown.new do |c|
        c.with_action { '<a href=# class="bs-a">Edit</a>'.html_safe }
        c.with_destructive_action do
          '<a href=# class="bs-a">Delete <span class="xi-icon fa-regular fa-trash-can"></span></a>'.html_safe
        end
      end
    end

    # For "destructive" actions it is recomended to
    # display a confirmation modal dialog
    #
    # @label With confirmation modal
    def with_confirmation_modal
      render Global::ActionsDropdown.new do |c|
        c.with_action { '<a href=# class="bs-a">Edit</a>'.html_safe }
        c.with_destructive_action do
          '<a href=# class="bs-a" data-confirm="Are you sure?" data-disable-with="Deleting...">Delete</a>'.html_safe
        end
      end
    end

    # Instead of an ellipsis icon, text can be shown in the button.
    # The button is then styled with the primary color of the platform.
    #
    # @label With text
    def with_text
      render Global::ActionsDropdown.new(text: 'Download') do |c|
        c.with_action { '<a href=# class="bs-a">Video HD</a>'.html_safe }
        c.with_action { '<a href=# class="bs-a">Slides</a>'.html_safe }
      end
    end
    # @!endgroup
  end
end
