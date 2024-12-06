# frozen_string_literal: true

class StatisticDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      available_submissions:,
      submitted_submissions:,
      submissions_with_content:,
      required_reviews:,
      finished_reviews:,
      nominations:,
      reviews:,
      submitted_reviews:,
      conflicts:,
      point_groups:,
    }.as_json(opts)
  end
end
