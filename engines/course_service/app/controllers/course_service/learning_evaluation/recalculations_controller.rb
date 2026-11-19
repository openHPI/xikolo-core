# frozen_string_literal: true

module CourseService
module LearningEvaluation # rubocop:disable Layout/IndentationWidth
  class RecalculationsController < ApplicationController
    respond_to :json

    def create
      unless course.needs_recalculation? && course.recalculation_allowed?
        return head(:created, content_type: 'text/plain')
      end

      LearningEvaluation::PersistForCourseJob.perform_later(course.id)

      head(:created, content_type: 'text/plain')
    end

    private

    def course
      @course ||= Course.by_identifier(params[:course_id]).take!
    end
  end
end
end
