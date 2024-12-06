# frozen_string_literal: true

module Global
  class LabeledCopyButtonPreview < ViewComponent::Preview
    def default
      render Global::LabeledCopyButton.new(label: 'Label', value: 'Value', button: 'Copy me!')
    end
  end
end
