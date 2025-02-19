# frozen_string_literal: true

module Video
  class TopicListPreview < ViewComponent::Preview
    def default
      render ::Video::TopicList.new(item: video_item(false), user: registered_user)
    end

    def locked_forum
      render ::Video::TopicList.new(item: video_item(true), user: registered_user)
    end

    private

    COURSE_ID = SecureRandom.uuid
    USER_ID = SecureRandom.uuid
    ITEM_ID = SecureRandom.uuid

    private_constant :COURSE_ID, :USER_ID, :ITEM_ID

    def course(forum_is_locked)
      Catalog::Course.new({
        id: COURSE_ID,
        course_code: 'video-topics',
        forum_is_locked:,
      })
    end

    def video_item(forum_is_locked)
      item = Course::Item.new({
        id: ITEM_ID,
        content_type: 'video',
        title: 'Video',
      })

      VideoItemPresenter.new(item:, course: course(forum_is_locked), user: registered_user)
    end

    def registered_user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user_id' => USER_ID,
        'user' => {'anonymous' => false},
      })
    end
  end
end
