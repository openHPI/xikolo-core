# frozen_string_literal: true

module AccountService
class Policy < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :policies

  default_scope { order(version: :desc) }
end
end
