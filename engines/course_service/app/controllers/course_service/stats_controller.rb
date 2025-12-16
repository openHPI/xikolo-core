# frozen_string_literal: true

module CourseService
class StatsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::PaginateResponder

  respond_to :json

  # get some simple stats, for example the enrollments per course

  def show
    stats = Rails.cache.fetch(
      "course.stats/#{stat_params.to_query}",
      expires_in: 1.hour,
      race_condition_ttl: 1.minute
    ) do
      Stat.new(stat_params)
    end

    respond_with stats
  end

  def decorate(res)
    StatDecorator.new res
  end

  private

  def stat_params
    params.permit :key, :course_id
  end
end
end
