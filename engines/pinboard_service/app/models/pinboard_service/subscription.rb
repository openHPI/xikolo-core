# frozen_string_literal: true

module PinboardService
class Subscription < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :subscriptions

  belongs_to :question

  default_scope { order created_at: :desc }
end
end
