# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Grade < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'grades'
    include Xikolo::PeerAssessment::Concerns::Grade

    attribute :id,            :uuid
    attribute :submission_id, :uuid
    attribute :base_points,   :float
    attribute :bonus_points,  :list
    attribute :delta,         :float
    attribute :absolute,      :boolean
    attribute :overall_grade, :float
    attribute :regradable,    :boolean
  end
end
