# frozen_string_literal: true

class Policy < ApplicationRecord
  default_scope { order(version: :desc) }
end
