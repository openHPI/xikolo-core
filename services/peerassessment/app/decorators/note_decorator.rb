# frozen_string_literal: true

class NoteDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      subject_id:,
      subject_type:,
      user_id:,
      text:,
      created_at:,
      updated_at:,
    }.as_json(opts)
  end
end
