# frozen_string_literal: true

module Course
  class DetailsCard < ApplicationComponent
    # Rendered at up to 356px wide, requested at 2x for high-density screens.
    VISUAL_WIDTH = 712

    # @param course [Course::CourseDetailsPresenter]
    # @param enrollment_count [Integer, nil] only passed when it may be shown
    def initialize(course, enrollment_count: nil)
      @course = course
      @enrollment_count = enrollment_count
    end

    private

    def course_format
      return if @course.course_format.blank?

      t(:"course.formats.#{@course.course_format}")
    end

    def classifier_titles
      @classifier_titles ||= @course.category_titles
    end

    def meta_info
      [].tap do |info|
        info << t('course.details_card.offered_by', teachers: @course.teacher_names) if @course.teacher_names.present?
        if @course.updated_at
          info << t('course.details_card.last_updated', date: l(@course.updated_at.to_date, format: :short))
        end
        info << t('course.details_card.enrollments', count: @enrollment_count) if @enrollment_count
      end
    end

    def start_countdown_secs
      starts_at = @course.effective_start_date
      return unless starts_at&.future?

      @start_countdown_secs ||= (starts_at - Time.zone.now).ceil
    end

    def show_teaser_button?
      @course.teaser_player.present?
    end

    def abstract_id
      "course-details-card-abstract-#{object_id}"
    end
  end
end
