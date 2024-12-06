# frozen_string_literal: true

class SubmissionStatisticsDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    if context[:only].present?
      {context[:only].to_sym => model.send(context[:only].to_sym)}
    else
      {
        total_submissions: model.total_submissions,
        total_submissions_distinct: model.total_submissions_distinct,
        max_points: model.max_points,
        avg_points: model.avg_points,
        unlimited_time: model.unlimited_time,
      }.tap do |attrs|
        context[:embed].each do |type|
          attrs[type.to_sym] = model.send(type.to_sym)
        end
      end
    end.as_json(opts)
  end
end
