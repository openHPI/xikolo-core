# frozen_string_literal: true

class Group < ApplicationRecord
  self.table_name = 'peer_assessment_groups'

  has_many :participants
end
