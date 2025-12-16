# frozen_string_literal: true

module CourseService
# We are temporarily duplicating the membership model from xi-account
module Duplicated # rubocop:disable Layout/IndentationWidth
  class Membership < ApplicationRecord
    self.table_name = :memberships

    belongs_to :group, class_name: 'CourseService::Duplicated::Group'
  end
end
end
