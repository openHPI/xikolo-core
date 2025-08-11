# frozen_string_literal: true

class Course::FreeReactivationsController < Abstract::AjaxController
  before_action :ensure_logged_in

  def create
    prerequisite = reactivatable_prerequisites.find do |pre|
      pre['course']['id'] == params.require(:reactivate)
    end

    unless prerequisite
      render status: :forbidden, json: {error: 'no_free_reactivation'}
      return
    end

    reactivate!(prerequisite)

    head :created
  rescue Restify::UnprocessableEntity
    head :unprocessable_entity
  end

  private

  def reactivatable_prerequisites
    @reactivatable_prerequisites ||= course_api.rel(:course)
      .get({id: params[:course_id]})
      .value!
      .rel(:prerequisite_status)
      .get({user_id: current_user.id})
      .value!['prerequisites']
      .select {|course| course['free_reactivation'] }
  end

  def reactivate!(prerequisite)
    course_api.rel(:enrollments).post({
      course_id: prerequisite['course']['id'],
      user_id: current_user.id,
    }).value!.rel(:reactivations).post({
      submission_date: CourseReactivation.config('period').weeks.from_now.iso8601,
    }).value!
  end
end
