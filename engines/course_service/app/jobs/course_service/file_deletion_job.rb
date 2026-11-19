# frozen_string_literal: true

module CourseService
  class FileDeletionJob < ApplicationJob
    queue_as :default

    def perform(uri)
      Xikolo::S3.object(uri).delete
    rescue URI::InvalidURIError
      # No valid URI, no deletion
    end
  end
end
