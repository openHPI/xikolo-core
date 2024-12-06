# frozen_string_literal: true

class Course::Admin::VisualEditPresenter
  class << self
    def for_course(id:)
      course = Course::Course.by_identifier(id).take!

      new(course)
    end
  end

  def initialize(course)
    @course = course
    @visual = @course.visual || @course.build_visual
  end

  attr_reader :visual

  def course_code
    @course.course_code
  end

  def course_id
    @course.id
  end

  def stream_prefix
    Xikolo.config.video_prefix.gsub('COURSE_CODE', @course.course_code)
  end

  def teaser_subtitles
    @visual.video&.subtitles.presence || []
  end

  def stream_collection
    return [] unless @visual.video_stream

    stream = @visual.video_stream
    [["#{stream.title} (#{stream.provider.name})", stream.id]]
  end

  def to_model
    @course
  end
end
