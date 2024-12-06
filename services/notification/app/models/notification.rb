# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :event
end
