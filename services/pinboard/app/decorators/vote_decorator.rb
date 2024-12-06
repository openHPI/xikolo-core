# frozen_string_literal: true

class VoteDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      value:,
      votable_id:,
      votable_type:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      user_id:,
    }.as_json(opts)
  end

  def to_event
    {
      id:,
        value:,
        votable_id:,
        votable_type:,
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601,
        user_id:,
        votable_user_id: votable.user_id,
        course_id:,
    }
  end
end
