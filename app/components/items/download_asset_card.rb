# frozen_string_literal: true

module Items
  class DownloadAssetCard < ApplicationComponent
    def initialize(title:, url:, file_type: nil, size: nil)
      @title = title
      @url = url
      @file_type = file_type
      @size = size
    end

    private

    def file_metadata
      parts = []
      parts << ".#{@file_type}" if @file_type.present?
      parts << number_to_human_size(@size) if @size.present?

      parts.join(' | ')
    end
  end
end
