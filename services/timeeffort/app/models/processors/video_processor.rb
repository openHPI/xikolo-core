# frozen_string_literal: true

module Processors
  class VideoProcessor < BaseProcessor
    attr_reader :video

    def initialize(item)
      super

      @video = nil
    end

    def load_resources!
      raise Errors::InvalidItemType unless item.content_type == 'video'

      @video = Duplicated::Video.find(item.content_id)
    rescue ActiveRecord::RecordNotFound
      raise Errors::LoadResourcesError
    end

    def calculate
      return if video.blank?

      @time_effort = video.duration
    end
  end
end
