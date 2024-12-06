# frozen_string_literal: true

class ItemConsumer < Msgr::Consumer
  def create_or_update
    return unless Xikolo.config.timeeffort['enabled']

    begin
      item = Item.find_or_create_by!(id: payload.fetch(:id)) do |i|
        # Set attributes on create
        i.content_id = payload.fetch(:content_id)
        i.content_type = payload.fetch(:content_type)
        i.section_id = payload.fetch(:section_id)
        i.course_id = payload.fetch(:course_id)
        # Add the time effort if it is provided. Additionally, set the
        # overwritten flag to not ignore already overwritten time efforts
        # for items (i.e. when cloning items).
        i.time_effort = payload.fetch(:time_effort, nil)
        i.time_effort_overwritten = true if payload[:time_effort].present?
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    # Update fields that might have changed since
    # we cannot ensure the correct order of events
    course_item = Xikolo.api(:course).value!
      .rel(:item)
      .get(id: item.id)
      .value!
    item.update! section_id: course_item['section_id']

    # Ignore automatic updates of items with not supported content type
    if item.calculation_supported?
      TimeEffortJob.create!(item_id: item.id).schedule
    end
  rescue Restify::NotFound
    remove_shadow_item item.id
  end

  def destroy
    return unless Xikolo.config.timeeffort['enabled']

    remove_shadow_item payload.fetch(:id)
  end

  private

  def remove_shadow_item(id)
    item = Item.find id
    TimeEffortJob.cancel_active_jobs item.id
    item.destroy
  rescue ActiveRecord::RecordNotFound
    # Do not fail if Item does not exist
  end
end
