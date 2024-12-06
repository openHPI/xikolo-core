# frozen_string_literal: true

module Global
  class DownloadButton < ApplicationComponent
    def initialize(url, text, attributes: {}, css_classes: '', type: nil)
      @url = url
      @text = text
      @attributes = attributes
      @css_classes = css_classes.split
      @type = type
    end

    def css_classes
      return 'btn btn-primary' if @css_classes.empty?

      @css_classes.join(' ')
    end

    def icon
      'download' if type == :download
    end

    private

    # Restrict allowed button types
    def type
      if %i[download progress].include? @type
        @type
      end
    end
  end
end
