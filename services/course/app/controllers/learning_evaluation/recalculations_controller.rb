# frozen_string_literal: true

module LearningEvaluation
  class RecalculationsController < ApplicationController
    respond_to :json

    def create
      unless course.needs_recalculation? && course.recalculation_allowed?
        return head(:created, content_type: 'text/plain')
      end

      LearningEvaluation::PersistForCourseWorker.perform_async(course.id)

      head(:created, content_type: 'text/plain')
    end

    private

    def course
      @course ||= Course.by_identifier(params[:course_id]).take!
    end
  end
end
