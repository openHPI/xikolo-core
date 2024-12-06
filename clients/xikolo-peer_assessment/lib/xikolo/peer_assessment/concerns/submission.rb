# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Submission
    extend ActiveSupport::Concern

    included do
      validates :user_id, presence: true
    end
  end
end
