# frozen_string_literal: true

module Global
  class DownloadButtonPreview < ViewComponent::Preview
    # @!group

    def default
      render Global::DownloadButton.new(
        '#',
        'Download',
        type: :download
      )
    end

    def disabled
      render Global::DownloadButton.new(
        '#',
        'Download',
        attributes: {disabled: true},
        type: :download
      )
    end

    def progress
      render Global::DownloadButton.new(
        '#',
        'Check my progress',
        css_classes: 'btn btn-default btn-outline',
        type: :progress
      )
    end

    # @!endgroup
  end
end
