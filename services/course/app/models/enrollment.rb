# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :course

  has_one :fixed_learning_evaluation,
    foreign_key: %i[user_id course_id],
    primary_key: %i[user_id course_id]

  has_one :course_progress,
    foreign_key: %i[user_id course_id],
    primary_key: %i[user_id course_id]

  default_scope lambda {
    order('enrollments.created_at DESC, enrollments.updated_at DESC')
  }
  scope :active, -> { where(deleted: false) }
  # In Rails 6, these could use begin-/end-less ranges
  scope :created_last_day, -> { where(created_at: 1.day.ago..) }
  scope :created_last_7days, -> { where(created_at: 7.days.ago..) }
  scope :created_at_latest, ->(date) { where(created_at: ..date) }
  scope :for_current_course, -> { joins(:course).merge(Course.current) }
  scope :reactivated, -> { where.not(forced_submission_date: nil) }
  scope :with_evaluation, lambda {
    left_outer_joins(:course_progress)
      .includes(:course) # The decorator accesses the course association to determine certificate achievements
      .select(
        'enrollments.*',
        'COALESCE(course_progresses.visits, 0) AS visits_visited',
        'COALESCE(course_progresses.max_visits, 0) AS visits_total',
        'COALESCE(course_progresses.visits_percentage_fpoints, 0)::float / 100 AS visits_percentage',
        <<~SQL.squish,
          LEAST(
            COALESCE((course_progresses.main_dpoints + course_progresses.bonus_dpoints), 0),
            COALESCE(course_progresses.max_dpoints, 0)
          ) AS user_dpoints
        SQL
        'COALESCE(course_progresses.max_dpoints, 0) AS maximal_dpoints',
        'COALESCE(course_progresses.points_percentage_fpoints, 0)::float / 100 AS points_percentage'
      )
  }

  validates :user_id,
    presence: true,
    uniqueness: {scope: :course_id, message: 'already enrolled'}
  validate :course_not_external

  after_commit(on: :create) do
    LearningEvaluation::UpdateCourseProgressWorker
      .perform_async(course_id, user_id)
  end

  after_commit(on: :update) do
    Msgr.publish(decorate_self, to: 'xikolo.course.enrollment.update')
  end

  after_commit do
    next unless forced_submission_date?

    NextDate::OnDemandExpiresSyncWorker.perform_async(course_id, user_id)
  end

  def completed?
    return completed unless completed.nil?
    unless course.records_released? &&
           has_attribute?(:user_dpoints) &&
           has_attribute?(:maximal_dpoints) &&
           has_attribute?(:visits_percentage)
      return false
    end
    return true if course.record_of_achievement? self

    course.status != 'active' && course.confirmation_of_participation?(self)
  end

  # Is the course currently (actively) reactivated for the user?
  def reactivated?
    # Use present check to return *true* / *false*, not *nil* (e.g., with safe navigation).
    forced_submission_date.present? && forced_submission_date.future?
  end

  # Was the course reactivated for the user (at some point)?
  def was_reactivated?
    !forced_submission_date.nil?
  end

  def effective_quantile
    # is the quantile recomputed?
    return quantile unless quantile.nil?
    # quantile is only generated among the users with RoA
    return unless course.record_of_achievement?(self)
    # on-the-fly if enrollment on demand (aka. visitts/results are newer)
    return unless was_reactivated?

    # order enrollments by user dpoints use quantile of first enrollment with
    # less or equal points than the current enrollment:
    course.enrollments.where(quantiled_user_dpoints: ..user_dpoints)
      .reorder(quantile: 'DESC').first.try(:quantile)
  end

  def last_visit
    items = Item.unscope(:order).joins(:section)
      .where(sections: {course_id:})
    Visit.reorder(updated_at: :desc).find_by(
      user_id:,
      item_id: items.select(:id)
    )
  end

  def decorate_self
    EnrollmentDecorator.decorate(self).as_event
  end

  class << self
    def instantiate_from_learning_evaluation(attributes, course)
      instantiate(attributes).with_course(course)
    end
  end

  def with_course(course)
    define_singleton_method(:course) { course }
    self
  end

  def completed_at
    return nil unless completed?

    graded_items = course.items.graded
    last_graded_item_date = nil
    result = Result.where(user_id:, item_id: graded_items.map(&:id))
      .order(created_at: :desc).first
    last_graded_item_date = result.created_at unless result.nil?
    last_graded_item_date
  end

  def self.with_learning_evaluation(enrollments)
    # group by section
    visits_query = Visit.where('user_id = enrollments.user_id').where('item_id = items.id')
    visited_items = <<~SQL.squish
      SUM (
        CASE
          WHEN
            EXISTS (#{visits_query.to_sql})
            AND NOT sections.optional_section
            AND NOT items.optional
          THEN 1
          ELSE 0
        END
      )
    SQL

    total_items = <<~SQL.squish
      SUM(
        CASE
          WHEN sections.optional_section OR items.optional
          THEN 0
          ELSE 1
        END
      )
    SQL

    results_query = Result.select('dpoints')
      .where('user_id = enrollments.user_id')
      .where('item_id = items.id')
      .order(
        Arel.sql(
          <<~SQL.squish
            (
              CASE
                WHEN items.proctored and enrollments.proctored
                THEN cast(extract(epoch from results.created_at) as integer)
                ELSE results.dpoints
              END
            ) DESC
          SQL
        )
      ).limit(1)
    user_dpoints = <<~SQL.squish
      COALESCE (
        SUM (
          CASE
            WHEN items.exercise_type IN ('main', 'bonus')
            THEN (#{results_query.to_sql})
            ELSE NULL
          END
        ), 0
      )
    SQL

    maximal_dpoints = <<~SQL.squish
      COALESCE (
        SUM (
          CASE
            WHEN items.exercise_type = 'main'
            THEN items.max_dpoints
            ELSE NULL
          END
        ), 0
      )
    SQL

    per_section = Enrollment.unscoped.from(enrollments.arel.as('enrollments')).select(
      'enrollments.id',
      'coalesce(sections.parent_id, sections.id) AS grouping_key',
      "#{visited_items} AS visited_items",
      "#{total_items} AS total_items",
      "#{user_dpoints} AS user_dpoints",
      "#{maximal_dpoints} AS maximal_dpoints"
    ).where.not(course: {sections: {
      alternative_state: 'parent',
    }}).where(course: {sections: {
      published: true,
      items: {published: true},
    }}).joins(
      <<~SQL.squish
        INNER JOIN courses ON courses.id = enrollments.course_id
        LEFT OUTER JOIN sections ON sections.course_id = courses.id
        LEFT OUTER JOIN items ON items.section_id = sections.id
      SQL
    ).group('enrollments.id, sections.id')
      .arel.as('per_section')

    # group by section that is graded
    group_rank = <<~SQL.squish
      row_number() OVER (
        PARTITION BY
          id,
          grouping_key
        ORDER BY
          (user_dpoints::float / nullif(maximal_dpoints, 0)) DESC,
          CASE
            WHEN user_dpoints = 0
            THEN -maximal_dpoints
            ELSE maximal_dpoints
          END DESC,
          (visited_items::float / nullif(total_items, 0)) DESC,
          CASE
            WHEN visited_items = 0
            THEN -total_items
            ELSE total_items
          END DESC
      )
    SQL

    per_graded_section = Enrollment.unscoped.from(per_section).select(
      'per_section.id',
      'per_section.visited_items',
      'per_section.total_items',
      'per_section.user_dpoints',
      'per_section.maximal_dpoints',
      "#{group_rank} AS group_rank"
    ).arel.as('per_graded_section')

    # now select the to grading sections based on group_rank
    # and sum all for each course
    per_course = Enrollment.unscoped.from(per_graded_section).select(
      'per_graded_section.id',
      'sum(per_graded_section.visited_items) AS visited_items',
      'sum(per_graded_section.total_items) AS total_items',
      'sum(per_graded_section.user_dpoints) AS user_dpoints',
      'sum(per_graded_section.maximal_dpoints) AS maximal_dpoints'
    ).where('coalesce(per_graded_section.group_rank, 1) = 1')
      .group('per_graded_section.id')
      .arel.as('per_course')

    # use the original query and
    # join fixed learning evaluation and the calculated data
    visits_percentage = <<~SQL.squish
      greatest(
        fixed_learning_evaluations.visits_percentage,
        per_course.visited_items * 100.0 / nullif(per_course.total_items, 0),
        0
      )
    SQL

    final_user_dpoints = <<~SQL.squish
      least(
        coalesce(fixed_learning_evaluations.user_dpoints, per_course.user_dpoints, 0),
        coalesce(fixed_learning_evaluations.maximal_dpoints, per_course.maximal_dpoints, 0)
      )
    SQL

    Enrollment.unscoped.from(enrollments.arel.as('enrollments')).select(
      'enrollments.*',
      'coalesce(per_course.visited_items, 0) AS visits_visited',
      'coalesce(per_course.total_items, 0) AS visits_total',
      "#{visits_percentage} AS visits_percentage",
      "#{final_user_dpoints} AS user_dpoints",
      'coalesce(fixed_learning_evaluations.maximal_dpoints, per_course.maximal_dpoints, 0) AS maximal_dpoints'
    ).left_outer_joins(:fixed_learning_evaluation)
      .joins(
        Enrollment.arel_table
          .join(per_course, Arel::Nodes::OuterJoin)
          .on(per_course[:id].eq(Enrollment.arel_table[:id]))
          .join_sources
      )
  end

  def points_percentage
    # With the persisted learning evaluation, we can read the percentage
    # from the corresponding `CourseProgress` record.
    # See the `.with_evaluation` scope for details.
    return read_attribute(:points_percentage) if has_attribute?(:points_percentage)

    # If this is not a dynamic learning evaluation, i.e. a regular enrollment
    # without the `.with_learning evaluation` scope applied, skip it.
    return unless has_attribute?(:maximal_dpoints) && has_attribute?(:user_dpoints)

    # Calculate the points percentage based on the dynamically computed
    # learning evaluation.
    return 0.0 if maximal_dpoints.zero?

    [user_dpoints.to_f / maximal_dpoints * 100, 100.0].min
  end

  def create_membership!
    Xikolo.api(:account).value!.rel(:memberships).post({
      user: user_id,
      group: course.students_group_name,
    }).value!
  end

  def archive!
    update! deleted: true
  end

  def course_not_external
    return if course.external_course_url.blank?

    errors.add(:external_course, "can't enroll in external course")
  end
end
