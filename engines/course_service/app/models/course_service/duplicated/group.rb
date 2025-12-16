# frozen_string_literal: true

module CourseService
# We are temporarily duplicating the group model from xi-account
module Duplicated # rubocop:disable Layout/IndentationWidth
  class Group < ApplicationRecord
    self.table_name = :groups
  end
end
end
