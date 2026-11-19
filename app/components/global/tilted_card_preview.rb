# frozen_string_literal: true

module Global
  class TiltedCardPreview < ViewComponent::Preview
    # @!group
    def accent_default
      render ::Global::TiltedCard.new(
        title: 'AI Service Center with two lines of text',
        subtitle: 'Themenwelte Subtitle',
        link: '/',
        color_scheme: 'bg-accent-50',
        tilt_direction: 'left'
      )
    end

    def primary_without_subtitle
      render ::Global::TiltedCard.new(
        title: 'AI Service Center',
        link: '/',
        color_scheme: 'bg-primary-250',
        tilt_direction: 'right'
      )
    end

    def secondary_without_link
      render ::Global::TiltedCard.new(
        title: 'AI Service Center',
        subtitle: 'Themenwelte Subtitle with two lines of text',
        color_scheme: 'bg-secondary-50'
      )
    end
    # @!endgroup
  end
end
