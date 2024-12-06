# frozen_string_literal: true

module Xikolo::PeerAssessment
  class RubricOption < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'rubric_options'
    include Xikolo::PeerAssessment::Concerns::RubricOption

    attribute :id,          :uuid
    attribute :rubric_id,   :uuid
    attribute :description, :string
    attribute :points,      :integer
  end
end
