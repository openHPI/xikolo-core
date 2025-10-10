# frozen_string_literal: true

module Course
  class CourseVisual < ApplicationComponent
    def initialize(url, width: nil, alt_text: '', css_classes: '')
      @url = url
      @width = width
      @alt_text = alt_text
      @css_classes = css_classes.split
    end

    private

    def css_classes
      @css_classes.join(' ')
    end

    def url
      Imagecrop.transform(@url || asset_url('defaults/course.png'), imagecrop_opts)
    end

    def imagecrop_opts
      {
        width: @width,
      }.compact
    end
  end
end
