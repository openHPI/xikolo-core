# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Review
    extend ActiveSupport::Concern

    included do
      validates :deadline, :submission_id, :step_id, :user_id, presence: true
    end
  end
end
