# frozen_string_literal: true

module PinboardService
module VotesHelper # rubocop:disable Layout/IndentationWidth
  def votes_sum
    if votes.loaded?
      votes.sum(&:value)
    else
      Vote.where(votable_id: id, votable_type: self.class.name).sum(:value)
    end
  end
end
end
