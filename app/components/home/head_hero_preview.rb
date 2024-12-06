# frozen_string_literal: true

module Home
  class HeadHeroPreview < ViewComponent::Preview
    def default
      render Home::HeadHero.new(
        'The basic head hero has some text'
      )
    end

    def with_call_to_action
      render Home::HeadHero.new(
        'The head hero image can have a custom call to action',
        call_to_action: {text: 'Click here', link: '/'}
      )
    end

    def l_size
      render Home::HeadHero.new(
        'The text of the claim can be smaller',
        call_to_action: {text: 'Click here', link: '/'},
        size: 'l'
      )
    end

    # @!group with_logo

    # With logo
    # ---------------
    # A logo will only appear for screen sizes s+
    #
    def with_logo
      render Home::HeadHero.new(
        'The head hero image can have a logo',
        image: {url: 'startpage/head_hero/logo', alt: ''}
      )
    end

    def with_logo_and_call_to_action
      render Home::HeadHero.new(
        'The head hero image can have a logo and a call to action',
        image: {url: 'startpage/head_hero/logo', alt: ''},
        call_to_action: {text: 'Click here', link: '/'}
      )
    end

    # @!endgroup
  end
end
