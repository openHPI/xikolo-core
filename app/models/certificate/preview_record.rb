# frozen_string_literal: true

module Certificate
  class PreviewRecord
    # @param template [Certificate::Template]
    # @param user [AccountService::User]
    def initialize(template, user)
      @template = template
      @user = user
    end

    attr_reader :user

    def render_data
      RenderPreviewDataPresenter.new(self, @template)
    end

    def course
      @course ||= CourseService::Course.find(@template.course_id)
    end

    def verification
      'jazzy-fuzzy-juicy-junky-pizza'
    end
  end
end
