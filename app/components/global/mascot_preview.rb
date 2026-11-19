# frozen_string_literal: true

module Global
  class MascotPreview < ViewComponent::Preview
    def with_message
      render ::Global::Mascot.new(
        message: 'Du hast es noch nicht ganz geschafft! Fast toll!'
      )
    end

    def without_message
      render ::Global::Mascot.new(message: nil)
    end
  end
end
