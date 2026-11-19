# frozen_string_literal: true

module CourseService
class ProgressDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  def as_api_v1(_opts)
    attrs = {}
    attrs[:resource_id] = model.resource_id
    attrs[:kind] = model.type.delete_prefix('courseservice::')
    attrs[:items] = decorate_items(model.items) if model.available_section?
    if model.section?
      attrs[:title] = model.title
      attrs[:available] = model.available_section?
      attrs[:alternative_state] = model.alternative_state
      attrs[:discarded] = model.child_section? && !model.best_alternative?
    end
    attrs
  end

  def decorate_items(items)
    items.map do |item|
      decorate_item item
    end
  end

  def decorate_item(item)
    {
      id: item.id,
      title: item.title,
      content_type: item.content_type,
      exercise_type: item.exercise_type,
      user_state: item.user_state,
      optional: item.optional?,
      max_points: format_dpoints(item.max_dpoints),
      user_points: format_dpoints(item.result),
      deadline_passed: item.lti_submission_deadline_passed?,
      pass_percentage: item.pass_percentage,
    }
  end

  def format_dpoints(dpoints)
    return nil if dpoints.nil?

    dpoints / 10.0
  end
end
end
