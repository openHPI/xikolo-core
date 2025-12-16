# frozen_string_literal: true

module CourseService
class SectionChoiceDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_api_v1(_opts)
    {
      user_id:,
      section_id:,
      choice_ids:,
    }
  end
end
end
