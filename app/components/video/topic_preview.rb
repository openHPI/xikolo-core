# frozen_string_literal: true

module Video
  class TopicPreview < ViewComponent::Preview
    def default
      render ::Video::Topic.new(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Fusce egestas libero sit amet nunc sodales, sit amet sagittis neque commodo.',
        'I have a question',
        timestamp: {raw: 163, formatted: '02:43'},
        tags: %w[Databases Programming],
        replies_count: 4,
        url: {link: '/', text: 'See more'}
      )
    end
  end
end
