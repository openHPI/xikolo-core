# frozen_string_literal: true

module Course
  class EntryAction < ApplicationComponent
    def initialize(course_id:, user:)
      @course = CourseService::Course.find(course_id)
      @user = user
    end

    def render?
      return false if @course.external_course_url.present?

      enrolled? ? @course.was_available? : @course.enrollable?
    end

    def call
      content = [text]
      content << helpers.pixelart_icon('arrow-right', css_class: 'size-3 shrink-0') if enrolled?

      link_to safe_join(content), url, class: 'x-btn x-btn-neutral w-full max-w-full rounded-2xl whitespace-normal'
    end

    private

    def enrolled?
      return @enrolled if defined?(@enrolled)

      @enrolled = !@user.anonymous? &&
                  CourseService::Enrollment.active.exists?(course_id: @course.id, user_id: @user.id)
    end

    def text
      t(enrolled? ? 'course.bottom_bar.continue_learning' : 'course.bottom_bar.enroll')
    end

    def url
      enrolled? ? course_resume_path(@course.course_code) : enrollments_path(course_id: @course.course_code)
    end
  end
end
