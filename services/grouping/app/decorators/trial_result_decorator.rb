# frozen_string_literal: true

class TrialResultDecorator < ApplicationDecorator
  def as_csv
    [
      object.id,
      object.waiting,
      object.result,
      object.created_at.iso8601,
      object.updated_at.iso8601,
      object.metric.name,
      object.trial.user_id,
      object.trial.test_group.index,
    ].join(',')
  end
end
