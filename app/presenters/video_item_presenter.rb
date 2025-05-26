# frozen_string_literal: true

class VideoItemPresenter < ItemPresenter
  include Rails.application.routes.url_helpers

  attr_reader :video
  attr_accessor :new_question, :implicit_tags

  class << self
    def build(item, course, user, params: {})
      video = Video::Video.find item['content_id']

      video_presenter = VideoPresenter.new(
        video:, user:, embed_resources: true, course:
      )
      new item:, video: video_presenter, course:, user:, params:
    end
  end

  def forum_locked?
    course_pinboard_closed? || Course::Section.find(@item['section_id']).pinboard_closed
  end

  def featured_image
    @video.thumbnail
  end

  def meta_tags
    super.merge(
      og: {
        # mandatory:
        title:,
        type: 'video',
        image: @video.pip_stream&.poster,
        url: Xikolo.base_url.join(
          course_item_path(
            course_id: @course.course_code,
            id: UUID(id).to_param
          )
        ),
        # optional
        description: @video.description,
        site_name: Xikolo.config.site_name,
      },
      video_forum_locked: forum_locked?
    )
  end

  private

  def current_url(with: {}, without: [])
    url_for @params.except(*Array.wrap(without)).merge(**with, only_path: true).to_unsafe_h
  end

  def implicit_tag_identifier
    {
      'Xikolo::Course::Section' => section_id,
      'Xikolo::Course::Item' => id,
    }
  end
end
