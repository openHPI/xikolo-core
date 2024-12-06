# frozen_string_literal: true

module Statistics
  class CustomFieldChart < ApplicationComponent
    def initialize(field:, course_id:)
      @field = field
      @course_id = course_id
    end

    private

    def headline
      I18n.t(:"dashboard.profile.#{@field}")
    end

    def legend_value
      I18n.t(:"admin.course_management.dashboard.#{@field}.course")
    end

    def data_path
      "/api/v2/statistics/dashboard/custom_field.json?course_id=#{@course_id}&name=#{@field}"
    end
  end
end
