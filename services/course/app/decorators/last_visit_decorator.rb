# frozen_string_literal: true

class LastVisitDecorator < ApplicationDecorator
  delegate_all

  def fields
    {
      item_id:,
      visit_date: last_visited&.iso8601,
    }
  end

  def as_json(_opts)
    fields
  end
end
