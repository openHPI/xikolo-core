# frozen_string_literal: true

module Collabspace
  class MembershipForm
    include ActiveModel::Model

    attr_accessor :user_id, :status

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Xikolo::Collabspace::Membership')
    end

    def persisted?
      false
    end
  end
end
