# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Group < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'groups'

    attribute :id, :uuid
  end
end
