# frozen_string_literal: true

class TrialDecorator < ApplicationDecorator
  delegate_all

  def as_json(*)
    {
      id:,
      user_id:,
      finished:,
      user_test_id:,
      group_index: (test_group.index if test_group.present?), # TODO: TEMPORARY
    }.as_json
  end
end
