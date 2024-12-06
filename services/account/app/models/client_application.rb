# frozen_string_literal: true

class ClientApplication < ApplicationRecord
  validates :name, presence: true
end
