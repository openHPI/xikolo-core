# frozen_string_literal: true

module Course
  class Visual < ApplicationRecord
    self.table_name = 'course_visuals'

    belongs_to :course, class_name: '::Course::Course'
    belongs_to :video, class_name: '::Video::Video', optional: true

    after_commit :delete_s3_object!, on: %i[update destroy]

    def video_stream
      video&.pip_stream
    end

    def video_stream_id
      video_stream&.id
    end

    def image_url
      Xikolo::S3.object(image_uri).public_url if image_uri?
    end

    private

    def delete_s3_object!
      # If the image URI has not been changed, we don't need to delete anything.
      return unless previous_changes.key?('image_uri')
      # If the image URI was nil, an image has been added. Don't delete it.
      return if previous_changes['image_uri'].first.nil?

      # In all other cases, delete the old S3 image object:
      #   - The image has been replaced. (['old123', 'new456'])
      #   - The image has been removed. (['abc123', nil])
      S3FileDeletionJob.set(wait: 1.hour).perform_later(previous_changes['image_uri'].first)
    end
  end
end
