# frozen_string_literal: true

class SectionProgress < ApplicationRecord
  self.primary_key = %i[section_id user_id]

  belongs_to :section

  # In the context of alternative sections, we have one progress per child section and
  # no progress for the parent section. Only the one child with the best progress has
  # a UUID set for alternative_progress_for, which points to the parent. This one is
  # used to calculate the overall course progress.
  scope :best_alternatives, -> { where.not(alternative_progress_for: nil) }

  after_commit(on: :destroy) do
    LearningEvaluation::UpdateCourseProgressWorker
      .perform_async(section.course_id, user_id)
  end

  def calculate!
    update!(
      visits: count_visits,
      main_dpoints: sum_dpoints_for(relevant_items.where(exercise_type: 'main')),
      main_exercises: count_results_for(relevant_items.where(exercise_type: 'main')),
      bonus_dpoints: sum_dpoints_for(relevant_items.where(exercise_type: 'bonus')),
      bonus_exercises: count_results_for(relevant_items.where(exercise_type: 'bonus')),
      selftest_dpoints: sum_dpoints_for(relevant_items.where(exercise_type: 'selftest')),
      selftest_exercises: count_results_for(relevant_items.where(exercise_type: 'selftest'))
    )

    alternative_progress.set_best_alternative! if for_alternative?
  end

  def points_percentage
    return 0 if goals.max_dpoints.zero?

    dpoints = main_dpoints + bonus_dpoints
    [dpoints.to_f / goals.max_dpoints * 100, 100].min
  end

  def visits_percentage
    return 0 if goals.max_visits.zero?

    [visits.to_f / goals.max_visits * 100, 100].min
  end

  def for_alternative?
    section.alternative_state == 'child'
  end

  private

  def relevant_items
    @relevant_items ||= if section.course.legacy?
                          section.items
                        else
                          Structure::UserItemsSelector.new(section.node, user_id).items
                        end
  end

  def goals
    @goals ||= section.goals(user_id)
  end

  def sum_dpoints_for(items)
    # For each of the given items, we want to gather exactly one result
    # (usually the best one) for the user, to sum them all up.
    matching_result = Result.select('dpoints')
      .where(user_id:)
      .where('item_id = items.id')
      .limit(1)

    # Special case: When the user has activated proctoring, we will take the
    # *last* result for all proctored items (usually homework and exams), not
    # necessarily the best one.
    points = if proctored_enrollment?
               matching_result.order(
                 Arel.sql('CASE WHEN items.proctored THEN created_at END DESC'),
                 Arel.sql('CASE WHEN NOT items.proctored THEN dpoints END DESC')
               )
             else
               matching_result.order(dpoints: :desc)
             end

    Item.from(
      items.unscope(:order).published.select(
        "(#{points.to_sql}) AS dpoints"
      ),
      :items
    ).sum(:dpoints)
  end

  def count_results_for(items)
    # Unscope the order as ordering is never needed for IN operator queries and
    # only takes up more time and space, especially if there is no sorted index
    # that can be used. In that case, all items would need to be sorted, only to
    # check if `results.item_id` is included in the (sorted) result.
    Result.select(:item_id)
      .where(user_id:, item: items.published.unscope(:order))
      .distinct
      .count
  end

  def count_visits
    relevant_items
      .joins(:user_visits)
      .joins(:section)
      .where(
        optional: false,
        published: true,
        visits: {user_id:},
        sections: {optional_section: false}
      ).count
  end

  def proctored_enrollment?
    # Explicit nil check because "normal" memoization does not work with booleans
    return @proctored_enrollment unless @proctored_enrollment.nil?

    @proctored_enrollment = Enrollment.exists?(
      course_id: section.course_id, user_id:, proctored: true
    )
  end

  def alternative_progress
    AlternativeSectionProgress.new(parent: section.parent, user: user_id)
  end
end
