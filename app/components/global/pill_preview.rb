# frozen_string_literal: true

module Global
  class PillPreview < ViewComponent::Preview
    # @!group
    # @param text
    def default(text: 'Databases')
      render Global::Pill.new(text)
    end

    def small
      render Global::Pill.new('Databases', size: :small)
    end

    def note_color
      render Global::Pill.new('Databases', color: :note)
    end
    # @!endgroup
  end
end
