# frozen_string_literal: true

module Global
  class ItemStatusPreview < ViewComponent::Preview
    # @!group

    # No type uses neutral color
    def default
      render Global::ItemStatus.new({
        text: 'This indicates a status of some sort',
        path: '#',
        title: 'Some status',
        icon_name: 'block-question',
        tooltip: 'There can be a tooltip on hover.',
      })
    end

    def success
      render Global::ItemStatus.new({
        text: 'This indicates a success of some sort',
        icon_name: 'circle-check',
        path: '#',
        title: 'Success',
      },
        color_scheme: 'success')
    end

    def error
      render Global::ItemStatus.new({
        text: 'This indicates an error or lack of something',
        icon_name: 'circle-xmark',
        path: '#',
        title: 'Error',
      },
        color_scheme: 'error')
    end

    def link
      render Global::ItemStatus.new({
        text: 'This colors the icon in link color',
        icon_name: 'link-horizontal',
        path: '#',
        title: 'Link',
      },
        color_scheme: 'link')
    end

    # Connected
    # ---------
    #
    # Items are connected via a vertical line.
    # The icon is shown surrounded by a circle.
    # All color scheme options are supported
    #
    # Sub-types:
    #
    # - filled circle (visited)
    # - dashed circle (optional)
    # - disabled (locked)
    #
    def connected
      render_with_template
    end

    def connected_with_color_scheme_variations
      render_with_template
    end
    # @!endgroup
  end
end
