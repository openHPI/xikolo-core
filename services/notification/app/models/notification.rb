# frozen_string_literal: true

class Notification < ApplicationRecord
  self.table_name = :notifications

  belongs_to :event
end
