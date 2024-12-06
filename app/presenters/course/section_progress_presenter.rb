# frozen_string_literal: true

class Course::SectionProgressPresenter < SectionPresenter
  def available?
    @section.available
  end

  def optional?
    @section.optional
  end

  def parent?
    @section.alternative_state == 'parent'
  end

  def self_test_stats
    exercise_stats_for @section.selftest_exercises
  end

  def main_exercise_stats
    exercise_stats_for @section.main_exercises
  end

  def bonus_exercise_stats
    exercise_stats_for @section.bonus_exercises
  end

  def description
    @section.description
  end

  def items
    # `@section.items` may be `nil` if the section is not available.
    # Make sure to always return an enumerable object and avoid a tri-state.
    return [] if @section.items.blank?

    @section.items.map do |i|
      item = Xikolo::Course::Item.new(i)
      ItemPresenter.for(item, course: @course, user: @user)
    end
  end

  def visits_stats
    Course::ProgressVisitsStatsPresenter.new @section.visits
  end

  def alternatives
    @section.attributes[:alternatives] # TODO: direct access fails
  end

  def best_alternative?
    @section.alternative_state == 'child' && !@section.discarded
  end

  def discarded_alternative?
    @section.alternative_state == 'child' && @section.discarded
  end

  def course_lang
    @course.lang
  end

  private

  def exercise_stats_for(stats)
    stats = {course: @course, user: @user}.merge(stats || {})
    Course::ProgressExerciseStatsPresenter.new stats
  end
end
