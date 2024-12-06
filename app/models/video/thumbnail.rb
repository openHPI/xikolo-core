# frozen_string_literal: true

module Video
  class Thumbnail < ::ApplicationRecord
    belongs_to :video, class_name: '::Video::Video'

    def file_url
      Xikolo::S3.object(file_uri).public_url if file_uri
    end

    # JSON format to be used for the +Video::VideoPlayer+ component.
    def as_json(*_args)
      {
        thumbnail: file_url,
        startPosition: start_time,
      }
    end
  end
end
