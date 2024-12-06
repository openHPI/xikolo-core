# frozen_string_literal: true

class ItemStatisticsDecorator < ApplicationDecorator
  delegate_all

  def as_api_v1(opts = {})
    if context[:only].present?
      {context[:only].to_sym => model.send(context[:only].to_sym)}
    else
      {
        total_submissions: model.total_submissions,
        total_submissions_distinct: model.total_submissions_distinct,
        perfect_submissions: model.perfect_submissions,
        perfect_submissions_distinct: model.perfect_submissions_distinct,
        max_points: model.max_points,
        avg_points: model.avg_points,
      }.tap do |attrs|
        context[:embed].each do |type|
          attrs[type.to_sym] = model.send(type.to_sym)
        end
      end
    end.as_json(opts)
  end
end
