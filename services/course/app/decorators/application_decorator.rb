# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  include ApiResponder::Formattable

  api_formats :json

  def item_attributes
    {
      content_type: item.content_type,
      content_id: item.content_id,
      exercise_type: item.exercise_type,
      submission_deadline: item.submission_deadline,
      submission_publishing_date: item.submission_publishing_date,
      max_points: (item.max_dpoints / 10.0 if item.max_dpoints),
    }
  end
end
