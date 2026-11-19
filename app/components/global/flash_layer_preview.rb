# frozen_string_literal: true

module Global
  class FlashLayerPreview < ViewComponent::Preview
    def default
      render Global::FlashLayer.new(:success_layer, 'Success! <br /> This is a flash layer message.')
    end
  end
end
