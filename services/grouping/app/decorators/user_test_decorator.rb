# frozen_string_literal: true

class UserTestDecorator < ApplicationDecorator
  delegate_all

  def as_json(*)
    {
      id:,
      name:,
      identifier:,
      description:,
      start_date: start_date.iso8601,
      end_date: end_date.iso8601,
      max_participants:,
      course_id:,
      metric_ids: metrics.map(&:id),
      finished: finished?,
      round_robin:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      test_groups_url: test_groups_url(context[:statistics] == true),
      metrics_url:,
      filters_url:,
    }.tap do |attrs|
      if context[:statistics]
        attrs.merge!(
          total_count:,
          finished_count:,
          waiting_count:,
          mean:,
          required_participants:
        )
      end
      if context[:export]
        attrs[:csv] = to_csv(metric_name: context[:metric_name])
      end
    end
  end

  def test_groups_url(statistics)
    h.test_groups_path(user_test_id: id, statistics:)
  end

  def metrics_url
    h.metrics_path(user_test_id: id)
  end

  def filters_url
    h.filters_path(user_test_id: id)
  end
end
