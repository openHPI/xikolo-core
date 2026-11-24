# frozen_string_literal: true

# A course item with the learner's progress on it, as shown by Course::ItemCard
class Course::LearnerItemPresenter
  include UUIDHelper

  # @param item [CourseService::Item] with the learner's state (`.user_state` scope)
  # @param course [CourseService::Course]
  # @param current [Boolean] whether the learner resumes the course at this item
  def initialize(item, course, current: false)
    @item = item
    @course = course
    @current = current
  end

  def id
    @item.id
  end

  def title
    @item.title
  end

  def label
    Course::Item::TypeLabel.from_resource(@item).text
  end

  def icon
    Course::Item::Icon.from_resource(@item).icon_class
  end

  # The current item is highlighted even when completed.
  def state
    if @current
      :current
    elsif progress_state.marked?
      :completed
    elsif locked?
      :locked
    else
      :default
    end
  end

  # Items outside their dates have no page for the learner. Other locked items,
  # e.g. quizzes past their deadline and locked exams, stay linked, as their
  # page explains the lock.
  def path
    return unless @item.unlocked?

    Rails.application.routes.url_helpers.course_item_path(@course.course_code, short_uuid(@item.id))
  end

  # Items are locked outside the time they (and their section) are available.
  def locked?
    !@item.unlocked?
  end

  private

  def progress_state
    @progress_state ||= Course::Item::ProgressState.new(
      content_type: @item.content_type,
      exercise_type: @item.exercise_type,
      user_state: @item.user_state,
      user_points: @item.result&./(10.0),
      max_points: @item.max_points,
      pass_percentage: @item.pass_percentage
    )
  end
end
