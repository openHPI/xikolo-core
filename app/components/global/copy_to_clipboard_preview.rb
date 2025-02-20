# frozen_string_literal: true

module Global
  class CopyToClipboardPreview < ViewComponent::Preview
    def default
      render Global::CopyToClipboard.new('a9a855db-b335-4ee1', tooltip: 'Copy ID')
    end
  end
end
