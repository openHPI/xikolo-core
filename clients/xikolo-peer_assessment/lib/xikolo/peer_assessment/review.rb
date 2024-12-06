# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Review < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'reviews'
    include Xikolo::PeerAssessment::Concerns::Review

    attribute :id,            :uuid
    attribute :step_id,       :uuid
    attribute :submission_id, :uuid
    attribute :user_id,       :uuid
    attribute :text,          :string
    attribute :submitted,     :boolean
    attribute :award,         :boolean
    attribute :feedback_grade, :integer
    attribute :train_review,  :boolean
    attribute :optionIDs,     :list
    attribute :deadline,      :date_time
    attribute :grade,         :integer
    attribute :extended,      :boolean
    attribute :suspended,     :boolean

    def submission(&)
      @submission ||= Xikolo::PeerAssessment::Submission.find submission_id
      Acfs.add_callback(@submission, &)

      @submission
    end
  end
end
