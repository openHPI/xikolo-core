# frozen_string_literal: true

module Xikolo::PeerAssessment
  # Super generic statistic resource to respond all kinds of simple requests asked by the Web Service

  class Statistic < Acfs::SingletonResource
    service Xikolo::PeerAssessment::Client, path: 'statistics'

    attribute :required_reviews,      :integer
    attribute :finished_reviews,      :integer

    attribute :available_submissions,    :integer
    attribute :submitted_submissions,    :integer
    attribute :submissions_with_content, :integer

    # Misc statistics
    attribute :point_groups,      :list # Point groups are used to create charts. Multiple point groups possible.
    attribute :conflicts,         :integer
    attribute :nominations,       :integer
    attribute :reviews,           :integer
    attribute :submitted_reviews, :integer

    # Average values, i.e. reviews per user, grades, ... transmitted as
    # array of key-value arrays [[key1, value1], [key2, value2], ...]
    attribute :average_values, :list
  end
end
