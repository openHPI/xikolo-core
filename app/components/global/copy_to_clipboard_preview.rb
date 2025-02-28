# frozen_string_literal: true

module Global
  class CopyToClipboardPreview < ViewComponent::Preview
    # @!group
    def default
      render Global::CopyToClipboard.new('a9a855db-b335-4ee1', tooltip: 'Copy ID')
    end

    def button
      render Global::CopyToClipboard.new('a9a855db-b335-4ee2', label: 'Copy ID', type: :button)
    end

    # @!endgroup
  end
end
