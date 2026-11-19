# frozen_string_literal: true

module Course
  class TeacherCard < ApplicationComponent
    # Rendered at 60px, requested at 2x for high-density screens.
    PICTURE_SIZE = 120

    def initialize(name:, description: nil, picture_url: nil)
      @name = name
      @description = description
      @picture_url = picture_url
    end

    private

    def picture?
      @picture_url.present?
    end

    def picture_src
      Imagecrop.transform(@picture_url, width: PICTURE_SIZE, height: PICTURE_SIZE)
    end

    def initials
      @name.to_s.split.first(2).pluck(0).join.upcase
    end

    def description?
      @description.present?
    end

    def description_html
      helpers.render_markdown(@description)
    end

    def description_id
      "teacher-card-description-#{object_id}"
    end
  end
end
