# frozen_string_literal: true

module Course::Admin::LearningEvaluation
  class RecalculationsController < ApplicationController
    before_action :recalculation_enabled?
    require_permission 'course.course.recalculate'

    def create
      course = Course::Course.by_identifier(params[:course_id]).take!

      return unless course.needs_recalculation?

      if course.recalculation_allowed?
        Xikolo.api(:course).value!
          .rel(:course_learning_evaluation)
          .post({}, params: {course_id: params[:course_id]})
          .value!

        add_flash_message :success, t(:'flash.success.recalculation_triggered')
      else
        add_flash_message :error, t(:'flash.error.recalculation_rejected')
      end
    rescue Restify::ResponseError
      add_flash_message :error, t(:'flash.error.recalculation_failed')
    ensure
      redirect_to course_sections_path(params[:course_id]), status: :see_other
    end

    private

    def auth_context
      the_course.context_id
    end

    def request_course
      Xikolo::Course::Course.find params[:course_id]
    end

    def recalculation_enabled?
      raise AbstractController::ActionNotFound if Xikolo.config.persisted_learning_evaluation.blank?
    end
  end
end
