# frozen_string_literal: true

# We are temporarily duplicating the membership model from xi-account
module Duplicated
  class Membership < ApplicationRecord
    belongs_to :group, class_name: '::Duplicated::Group'
  end
end
