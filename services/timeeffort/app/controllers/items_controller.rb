# frozen_string_literal: true

class ItemsController < RESTController
  respond_to :json

  has_scope :section_id do |_controller, scope, value|
    scope.for_section value.to_s
  end

  has_scope :course_id do |_controller, scope, value|
    scope.for_course value.to_s
  end

  rfc6570_params index: %i[section_id course_id]

  def index
    respond_with collection
  end

  def create
    item = Item.create item_params

    respond_with item
  end

  def show
    respond_with resource
  end

  def overwrite_time_effort
    if params[:time_effort].blank?
      return render status: :unprocessable_entity, json: {errors: 'time_effort_required'}
    end

    item = Item.find(params.require(:item_id))
    overwrite_for!(item, params[:time_effort])

    head :no_content
  rescue Errors::OverwriteTimeEffortError => e
    render status: :unprocessable_entity, json: {errors: e.reason}
  rescue Restify::ClientError => e
    render status: :unprocessable_entity, json: {errors: e.errors}
  end

  def clear_overwritten_time_effort
    item = Item.find(params.require(:item_id))

    clear_for!(item)

    respond_with item
  rescue Restify::ClientError => e
    render status: :unprocessable_entity, json: {errors: e.errors}
  end

  private

  def overwrite_for!(item, time_effort)
    # Lock item to avoid cases where the overwrite is ignored
    item.with_lock do
      unless item.overwrite_time_effort(time_effort).success?
        raise Errors::OverwriteTimeEffortError
      end

      patch_course_item!(item.id, time_effort)
    end
  end

  def clear_for!(item)
    return unless item.time_effort_overwritten

    # Lock item to avoid cases where the reset is ignored
    item.with_lock do
      item.clear_overwritten_time_effort

      patch_course_item!(item.id, item.calculated_time_effort)
    end
  end

  def patch_course_item!(item_id, time_effort)
    Xikolo.api(:course).value!
      .rel(:item)
      .patch({time_effort:}, {id: item_id})
      .value!
  end

  def item_params
    params.permit :id,
      :content_type,
      :content_id,
      :section_id,
      :course_id,
      :time_effort,
      :time_effort_overwritten
  end
end
