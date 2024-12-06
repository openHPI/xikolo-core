# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module RubricOption
    extend ActiveSupport::Concern

    included do
      validates :rubric_id, :points, presence: true
    end
  end
end
