# frozen_string_literal: true

class Policy < ApplicationRecord
  self.table_name = :policies

  default_scope { order(version: :desc) }
end
