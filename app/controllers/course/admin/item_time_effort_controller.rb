# frozen_string_literal: true

class Course::Admin::ItemTimeEffortController < Abstract::AjaxController
  respond_to :json

  before_action :ensure_logged_in

  def show
    authorize! 'course.content.edit'

    render status: :ok, json: overwritten_time_effort(time_effort_item)
  rescue Restify::ClientError
    render status: :unprocessable_entity, json: {errors: 'show_time_effort_failed'}
  end

  def update
    authorize! 'course.content.edit'
    time_effort_item
      .rel(:overwritten_time_effort)
      .put(time_effort: params.fetch(:time_effort))
      .value!

    head :no_content
  rescue Restify::ClientError
    render status: :unprocessable_entity, json: {errors: 'update_time_effort_failed'}
  end

  def destroy
    authorize! 'course.content.edit'
    item = time_effort_item
      .rel(:overwritten_time_effort)
      .delete
      .value!

    render status: :ok, json: overwritten_time_effort(item)
  rescue Restify::ClientError
    render status: :unprocessable_entity, json: {errors: 'reset_time_effort_failed'}
  end

  private

  def time_effort_item
    @time_effort_item ||= Xikolo.api(:timeeffort).value!
      .rel(:item)
      .get(id: item_id)
      .value!
  end

  def item_id
    params.fetch(:item_id)
  end

  def overwritten_time_effort(item)
    {
      time_effort: item['time_effort'],
      calculated_time_effort: item['calculated_time_effort'],
      time_effort_overwritten: item['time_effort_overwritten'],
    }
  end

  def auth_context
    course['context_id']
  end

  def course
    @course ||= Xikolo.api(:course).value!.rel(:course).get(id: params[:course_id]).value!
  end
end
