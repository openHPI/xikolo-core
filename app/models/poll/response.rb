# frozen_string_literal: true

module Poll
  class Response < ::ApplicationRecord
    self.table_name = 'poll_responses'

    belongs_to :poll

    validates :choices, presence: true
    validates :user_id, uniqueness: {scope: :poll_id}
    validates :choices,
      length: {maximum: 1, unless: -> { poll.allow_multiple_choices? }}
  end
end
