# frozen_string_literal: true

class Course::Visual::Clone < ApplicationOperation
  # param visual [Duplicated::Visual]
  # param course [Course]
  def initialize(visual, course)
    super()
    @visual = visual
    @course = course
  end

  def call
    return unless @visual

    clone_image!
    clone_video!

    @course.visual
  end

  private

  def clone_image!
    file_uri = copy_file(@visual.image_uri)

    return unless file_uri

    begin
      if @course.visual
        @course.visual.update!(image_uri: file_uri)
      else
        @course.create_visual!(image_uri: file_uri)
      end
    rescue ActiveRecord::RecordInvalid
      # noop
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def clone_video!
    return if @visual.video_stream_id.blank?

    if @course.visual
      @course.visual.create_video!(pip_stream_id: @visual.video_stream_id)
    else
      ActiveRecord::Base.transaction do
        @course.build_visual.tap do |visual|
          visual.create_video!(pip_stream_id: @visual.video_stream_id)
          visual.save!
        end
      end
    end

    clone_subtitles!
  rescue ActiveRecord::RecordInvalid
    # Gracefully fail, the visual will not be cloned.
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def clone_subtitles!
    video = @course.visual&.video
    old_video = @visual&.video

    return unless video
    return unless old_video.subtitles&.any?

    old_video.subtitles.each do |subtitle|
      subtitle.clone(video_id: video.id)
    end
  end

  def copy_file(uri)
    return unless uri

    original = Xikolo::S3.object(uri)
    # Replace course ID in key
    key = original.key.split('/').tap do |parts|
      parts[1] = UUID4(@course.id).to_s(format: :base62)
    end.join('/')

    Xikolo::S3.copy_to(original, target: key, bucket: :course, acl: 'public-read')
  rescue Aws::S3::Errors::ServiceError
    # Do not fail if the file cannot be copied.
  end
end
