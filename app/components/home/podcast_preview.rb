# frozen_string_literal: true

module Home
  class PodcastPreview < ViewComponent::Preview
    def default
      render Home::Podcast.new(
        'Knowledge Podcast',
        podcasts: [
          {title: 'Spotify', icon: 'spotify', link: 'https://www.example.com/spotify'},
          {title: 'Apple', icon: 'podcast', link: 'https://www.example.com/apple'},
        ],
        call_to_action: {link: '/'}
      )
    end
  end
end
