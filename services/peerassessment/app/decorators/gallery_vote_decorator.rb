# frozen_string_literal: true

class GalleryVoteDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      rating:,
      user_id:,
      shared_submission_id:,
    }.as_json(opts)
  end
end
