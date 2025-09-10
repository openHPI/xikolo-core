# frozen_string_literal: true

class PersistRankingWorker
  include Sidekiq::Job

  def perform(course_id)
    enrollments = Enrollment.where(course_id:)
    # 1. Clear all previous quantiles:
    # rubocop:disable Rails/SkipsModelValidations
    enrollments.update_all quantile: nil, quantiled_user_dpoints: nil
    # rubocop:enable Rails/SkipsModelValidations
    # 2. Load learning evaluation data:
    enrollments = Enrollment.with_learning_evaluation(enrollments)
    # 3. Set quantiles for all users with more than 50% of the total points:
    course = Course.find(course_id)
    ranked_enrollments = Enrollment
      .from(enrollments.arel.as('enrollments'))
      .select(
        'enrollments.id',
        'cume_dist() OVER (ORDER BY user_dpoints) AS quantile',
        'enrollments.user_dpoints'
      ).where(
        '((enrollments.user_dpoints * 1.0) / NULLIF(enrollments.maximal_dpoints,0)) >= ? / 100.0',
        course.roa_threshold_percentage
      )

    sql = <<-SQL.squish
      UPDATE enrollments
        SET quantile = ranked_enrollments.quantile,
          quantiled_user_dpoints = ranked_enrollments.user_dpoints
      FROM (#{ranked_enrollments.to_sql}) AS ranked_enrollments
      WHERE enrollments.id = ranked_enrollments.id
    SQL
    ActiveRecord::Base.connection.execute sql
  end
end
