# frozen_string_literal: true

module AccountService
class ClientApplication < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :client_applications

  validates :name, presence: true
end
end
