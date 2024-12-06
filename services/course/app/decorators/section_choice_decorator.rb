# frozen_string_literal: true

class SectionChoiceDecorator < ApplicationDecorator
  delegate_all

  def as_api_v1(_opts)
    {
      user_id:,
      section_id:,
      choice_ids:,
    }
  end
end
