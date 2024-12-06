# frozen_string_literal: true

module Video
  class TopicList < ApplicationComponent
    def initialize(item:, user:)
      @item = item
      @user = user
    end

    private

    def render?
      @user.logged_in? && topics
    end

    def topics
      @topics ||= pinboard_api.rel(:topics)
        .get(item_id: @item.id)
        .value!
        .map {|t| VideoItemTopicPresenter.new(t, @item.course_code) }
        .sort
    rescue Restify::NetworkError, Restify::ResponseError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)

      # Return nil so the component will be hidden (see #render?)
      nil
    end

    def allow_topic_creation
      !@item.course_pinboard_closed?
    end

    def empty_state
      allow_topic_creation && topics.blank?
    end

    def topic_url(topic)
      {
        link: topic.url,
        text: allow_topic_creation ? t(:'items.show.video.view_or_answer') : t(:'items.show.video.read_more'),
      }
    end

    def new_topic
      Pinboard::TopicForm.new
    end

    def pinboard_api
      @pinboard_api ||= Xikolo.api(:pinboard).value!
    end
  end
end
