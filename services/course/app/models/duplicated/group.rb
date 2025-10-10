# frozen_string_literal: true

# We are temporarily duplicating the group model from xi-account
module Duplicated
  class Group < ApplicationRecord
    self.table_name = :groups
  end
end
