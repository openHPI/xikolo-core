# frozen_string_literal: true

class ProgressDecorator < ApplicationDecorator
  def as_api_v1(_opts)
    attrs = {}
    attrs[:resource_id] = model.resource_id
    attrs[:kind] = model.type
    attrs[:visits] = decorate_visits unless model.unavailable_section?
    attrs[:items] = decorate_items(model.items) if model.available_section?
    if model.section?
      attrs[:title] = model.title
      attrs[:description] = model.description
      attrs[:position] = model.position
      attrs[:available] = model.available_section?
      attrs[:parent] = model.parent_section?
      attrs[:parent_id] = model.parent_id
      attrs[:alternative_state] = model.alternative_state
      attrs[:discarded] = model.child_section? && !model.best_alternative?
      attrs[:optional] = model.optional?
      attrs[:required_section_ids] = model.required_section_ids
    end
    if model.available_section?
      decorate_results attrs, model.results
    elsif !model.section? # course
      decorate_merged_results attrs, model.results
    end
    attrs
  end

  def decorate_visits
    {
      total: model.visited_total,
      user: model.visited_user,
      percentage: model.visited_percentage,
    }
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
      icon_type: item.icon_type,
      max_points: format_dpoints(item.max_dpoints),
      user_points: format_dpoints(item.result),
      time_effort: item.time_effort,
      open_mode: item.open_mode,
    }
  end

  def decorate_results(attrs, results)
    results.each do |result|
      attrs["#{result.exercise_type}_exercises"] = decorate_result result
    end
  end

  def decorate_merged_results(attrs, results)
    results.group_by(&:exercise_type).each do |exercise_type, grouped_results|
      if exercise_type == 'selftest'
        grouped_results = grouped_results.reject(&:section_optional)
      end
      attrs["#{exercise_type}_exercises"] =
        decorate_merged_result(grouped_results)
    end
  end

  def decorate_result(result)
    {
      max_points: format_dpoints(result.max_dpoints),
      graded_points: format_dpoints(result.graded_dpoints),
      submitted_points: format_dpoints(result.submitted_dpoints),
      total_exercises: result.total_exercises,
      graded_exercises: result.graded_exercises,
      submitted_exercises: result.submitted_exercises,
      next_publishing_date: result.next_publishing_date&.iso8601,
      last_publishing_date: result.last_publishing_date&.iso8601,
      items: decorate_items(model.items_for(result)),
    }
  end

  def decorate_merged_result(result)
    {
      max_points: format_dpoints(
        result.filter_map(&:max_dpoints).sum
      ),
      graded_points: format_dpoints(
        result.filter_map(&:graded_dpoints).sum
      ),
      submitted_points: format_dpoints(
        result.filter_map(&:submitted_dpoints).sum
      ),
      total_exercises: result.filter_map(&:total_exercises).sum,
      graded_exercises: result.filter_map(&:graded_exercises).sum,
      submitted_exercises: result.filter_map(&:submitted_exercises).sum,
    }
  end

  def format_dpoints(dpoints)
    return nil if dpoints.nil?

    dpoints / 10.0
  end
end
