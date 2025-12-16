# frozen_string_literal: true

module CourseService
class Progress # rubocop:disable Layout/IndentationWidth
  extend ActiveModel::Naming

  attr_reader :type, :items, :results
  attr_writer :best_alternative

  def initialize(resource, items, results)
    @type = resource.class.to_s.downcase.delete_prefix('courseservice::')
    @resource = resource
    @items = items
    @results = results
  end

  def resource_id
    @resource.id
  end

  def section?
    @type == 'section'
  end

  def course?
    @type == 'course'
  end

  def optional?
    section? && @resource.optional?
  end

  def available_section?
    section? && was_unlocked?
  end

  def unavailable_section?
    section? && !was_unlocked?
  end

  def parent_section?
    @resource.parent? if section?
  end

  def parent_id
    @resource.parent_id if section?
  end

  def child_section?
    parent_id.present?
  end

  def was_unlocked?
    @resource.start_date.nil? || @resource.start_date <= Time.zone.now
  end

  def title
    @resource.title
  end

  def description
    @resource.description
  end

  def position
    @resource.position
  end

  def visited_total
    if course?
      @items.reject(&:in_optional_section?)
    else
      @items
    end.count(&:mandatory?)
  end

  def visited_user
    @items.inject(0) do |count, item|
      if item.visit.nil? || item.optional? \
        || (course? && item.in_optional_section?)
        count
      else
        count + 1
      end
    end
  end

  def visited_percentage
    (visited_user * 100) / visited_total
  rescue ZeroDivisionError
    0
  end

  def items_for(result)
    @items.select do |item|
      result.exercise_ids.include? item.id
    end
  end

  def best_alternative?
    child_section? && @best_alternative
  end

  def alternative_state
    return 'parent' if parent_section?

    'child' if child_section?
  end

  def required_section_ids
    @resource.required_section_ids
  end
end
end
