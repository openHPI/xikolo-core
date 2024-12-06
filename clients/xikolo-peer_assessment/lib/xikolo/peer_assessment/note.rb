# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Note < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'notes'

    attribute :id,           :uuid
    attribute :subject_id,   :uuid
    attribute :subject_type, :string
    attribute :user_id,      :uuid
    attribute :text,         :string
    attribute :created_at,   :date_time
    attribute :updated_at,   :date_time

    # Fetches the user object of the note author
    def author!(&)
      @author ||= Xikolo::Account::User.find user_id
      Acfs.add_callback(@author, &)

      @author
    end
  end
end
