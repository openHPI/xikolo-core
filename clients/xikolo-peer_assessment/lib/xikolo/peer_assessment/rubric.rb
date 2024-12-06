# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Rubric < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'rubrics'
    include Xikolo::PeerAssessment::Concerns::Rubric

    attribute :id,                 :uuid
    attribute :peer_assessment_id, :uuid
    attribute :title,              :string
    attribute :hints,              :string
    attribute :position,           :integer
    attribute :team_evaluation,    :boolean, default: false

    # deprecated
    def options!(&)
      @options ||= Xikolo::PeerAssessment::RubricOption.where rubric_id: id
      Acfs.add_callback(@options, &)
      @options
    end
  end
end
