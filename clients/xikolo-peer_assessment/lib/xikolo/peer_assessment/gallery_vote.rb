# frozen_string_literal: true

module Xikolo::PeerAssessment
  class GalleryVote < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'gallery_votes'

    attribute :id,            :uuid
    attribute :rating,        :integer
    attribute :user_id,       :uuid
    attribute :shared_submission_id, :uuid
  end
end
