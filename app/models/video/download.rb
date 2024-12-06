# frozen_string_literal: true

module Video
  class Download
    SUPPORTED_QUALITIES = %i[hd sd].freeze

    def initialize(stream_id, quality)
      @stream_id = stream_id
      @quality = quality.to_sym
    end

    def download_link
      raise NoQualityAvailableError unless quality_available?
      raise NoQualityAvailableError unless quality_supported?

      downloads[@quality]
    end

    private

    def quality_available?
      downloads[@quality].present?
    end

    def quality_supported?
      SUPPORTED_QUALITIES.include? @quality
    end

    def downloads
      @downloads ||= Stream.find(@stream_id).current_downloads
    end

    class NoQualityAvailableError < StandardError; end
    class QualityNotSupportedError < StandardError; end
    class VideoNotAvailableError < StandardError; end
  end
end
