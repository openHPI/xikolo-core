# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Grade
    extend ActiveSupport::Concern

    included do
      validates :submission_id, presence: true
    end
  end
end
