# frozen_string_literal: true

module Global
  class FaIconPreview < ViewComponent::Preview
    # @!group

    def search
      render Global::FaIcon.new('magnifying-glass')
    end

    def plus
      render Global::FaIcon.new('plus')
    end

    def minus
      render Global::FaIcon.new('minus')
    end

    def check
      render Global::FaIcon.new('check')
    end

    def times
      render Global::FaIcon.new('xmark')
    end

    def up
      render Global::FaIcon.new('chevron-up')
    end

    def down
      render Global::FaIcon.new('chevron-down')
    end

    def left
      render Global::FaIcon.new('chevron-left')
    end

    def right
      render Global::FaIcon.new('chevron-right')
    end

    def tail_up
      render Global::FaIcon.new('arrow-up')
    end

    def tail_down
      render Global::FaIcon.new('arrow-down')
    end

    def tail_right
      render Global::FaIcon.new('arrow-right')
    end

    def tail_left
      render Global::FaIcon.new('arrow-left')
    end

    def dashboard
      render Global::FaIcon.new('grid-2')
    end

    def certificates
      render Global::FaIcon.new('medal')
    end

    def achievements
      render Global::FaIcon.new('trophy')
    end

    def settings
      render Global::FaIcon.new('gear')
    end

    def profile
      render Global::FaIcon.new('user')
    end

    def menu
      render Global::FaIcon.new('bars')
    end

    def external
      render Global::FaIcon.new('arrow-up-right-from-square')
    end

    def refresh
      render Global::FaIcon.new('arrow-rotate-left')
    end

    def hashtag
      render Global::FaIcon.new('hashtag')
    end
    # @!endgroup

    # Two icons can be combined by concatenating their names with a '+' symbol.
    # The stacked icon will appear in the top-right corner.
    # The styling currently only supports circulars icon stacked on top.
    #
    # @label Combined icons
    def combined_icons
      render Global::FaIcon.new('lightbulb-on+circle-star')
    end
  end
end
