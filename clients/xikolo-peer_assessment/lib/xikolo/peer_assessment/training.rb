# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class Training < Xikolo::PeerAssessment::Step
      service Xikolo::PeerAssessment::Client, path: 'trainings'
      include Xikolo::PeerAssessment::Concerns::Training

      attribute :required_reviews, :integer
      attribute :training_opened,  :boolean
    end
  end
end
