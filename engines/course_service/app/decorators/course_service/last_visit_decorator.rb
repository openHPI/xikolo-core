# frozen_string_literal: true

module CourseService
class LastVisitDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
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
end
