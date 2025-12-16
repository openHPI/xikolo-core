# frozen_string_literal: true

module CourseService
module Duplicated # rubocop:disable Layout/IndentationWidth
  class Visual < ApplicationRecord
    self.table_name = 'course_visuals'

    belongs_to :course
    belongs_to :video, class_name: 'CourseService::Duplicated::Video', optional: true

    def video_stream_id
      video&.pip_stream_id
    end

    def image_url
      Xikolo::S3.object(image_uri).public_url if image_uri?
    end
  end
end
end
