# frozen_string_literal: true

class CourseProgress < ApplicationRecord
  self.primary_key = %i[course_id user_id]

  # `0_00..100_00` are the fixed point representation of 0.00% - 100.00%
  validates_inclusion_of :points_percentage_fpoints, in: 0_00..100_00
  validates_inclusion_of :visits_percentage_fpoints, in: 0_00..100_00

  belongs_to :course

  has_one :fixed_learning_evaluation,
    foreign_key: %i[user_id course_id],
    primary_key: %i[user_id course_id]

  def calculate!
    # The `.or` is a logical union.
    progresses = regular_section_progresses.or best_alternative_section_progresses

    aggregated = progresses.select(
      'COALESCE(SUM(visits), 0) AS visits,' \
      'COALESCE(SUM(main_dpoints), 0) AS main_dpoints,' \
      'COALESCE(SUM(main_exercises), 0) AS main_exercises,' \
      'COALESCE(SUM(bonus_dpoints), 0) AS bonus_dpoints,' \
      'COALESCE(SUM(bonus_exercises), 0) AS bonus_exercises,' \
      'COALESCE(SUM(selftest_dpoints), 0) AS selftest_dpoints,' \
      'COALESCE(SUM(selftest_exercises), 0) AS selftest_exercises'
    ).take!

    # (1) Assign the current visits / points so that (2) operates on
    # the recent values.
    assign_attributes(
      visits: aggregated.visits,
      main_dpoints: aggregated.main_dpoints,
      main_exercises: aggregated.main_exercises,
      bonus_dpoints: aggregated.bonus_dpoints,
      bonus_exercises: aggregated.bonus_exercises,
      selftest_dpoints: aggregated.selftest_dpoints,
      selftest_exercises: aggregated.selftest_exercises,
      max_dpoints: count_max_dpoints,
      max_visits: count_max_visits
    )

    # (2) Recalculate and update points / visits percentages so the
    # `Achievement::*` classes can use the updated values to determine
    # the achievement dates.
    assign_attributes(
      points_percentage_fpoints: calculate_points_percentage_fpoints,
      visits_percentage_fpoints: calculate_visits_percentage_fpoints
    )

    save!
  end

  def points_percentage
    points_percentage_fpoints.to_f / 100
  end

  def visits_percentage
    visits_percentage_fpoints.to_f / 100
  end

  private

  def regular_section_progresses
    SectionProgress.where(
      section: course.sections.published.where(alternative_state: 'none'),
      user_id:
    )
  end

  def best_alternative_section_progresses
    SectionProgress.best_alternatives.where(
      section: course.sections.published.where(alternative_state: 'child'),
      user_id:
    )
  end

  # Overall course progress calculation regarding the achieved item visits and
  # points for a user in a specific course.
  # This will become the only place where the user's progress is calculated.
  def count_max_dpoints
    # Sum up points for the best alternative's items of each alternative section
    user_dpoints = course.sections.where(alternative_state: 'parent').sum do |section|
      best_section = AlternativeSectionProgress.new(parent: section, user: user_id).best_alternative.section

      # Ignore parent section without published children.
      next 0 if best_section.blank?

      best_section.items.published.where(exercise_type: 'main').sum(:max_dpoints)
    end

    # ...and add to the points for items in regular sections
    course.goals.max_dpoints + user_dpoints
  end

  def count_max_visits
    # Sum up visits for the best alternative's items of each alternative section
    user_visits = course.sections.where(alternative_state: 'parent').sum do |section|
      best_section = AlternativeSectionProgress.new(parent: section, user: user_id).best_alternative.section

      # Ignore parent section without published children.
      next 0 if best_section.blank?

      best_section.items.published.mandatory.count
    end

    # ...and add to the visits for items in regular sections
    course.goals.max_visits + user_visits
  end

  def calculate_points_percentage_fpoints
    max = fixed_learning_evaluation&.maximal_dpoints || max_dpoints

    return 0_00 if max.zero?

    dpoints = [
      fixed_learning_evaluation&.user_dpoints || (main_dpoints + bonus_dpoints),
      fixed_learning_evaluation&.maximal_dpoints || max_dpoints,
    ].min

    [dpoints * 100_00 / max, 100_00].min
  end

  def calculate_visits_percentage_fpoints
    progress_visits_percentage =
      if max_visits.zero?
        0_00
      else
        [visits * 100_00 / max_visits, 100_00].min
      end

    fixed_visits_percentage =
      (fixed_learning_evaluation&.visits_percentage.to_f * 1_00).to_i

    [
      progress_visits_percentage,
      fixed_visits_percentage,
    ].max
  end
end
