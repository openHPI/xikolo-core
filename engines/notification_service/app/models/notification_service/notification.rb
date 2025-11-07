# frozen_string_literal: true

module NotificationService
class Notification < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :notifications

  belongs_to :event
end
end
