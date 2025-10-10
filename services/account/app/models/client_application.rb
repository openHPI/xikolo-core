# frozen_string_literal: true

class ClientApplication < ApplicationRecord
  self.table_name = :client_applications

  validates :name, presence: true
end
