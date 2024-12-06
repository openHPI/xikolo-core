# frozen_string_literal: true

module Video
  class Topic < ApplicationComponent
    def initialize(text, title, timestamp: {raw: nil, formatted: nil}, tags: [], replies_count: 0,
                   url: {text: '', link: nil})
      @text = text
      @title = title
      @timestamp = timestamp
      @tags = tags
      @replies_count = replies_count
      @url = url
    end

    def topic_tags
      if @tags.any?
        tags = [@tags[0]]
        if @tags.length > 1
          tags << "+ #{@tags.length - 1}"
        end
      end
    end
  end
end
