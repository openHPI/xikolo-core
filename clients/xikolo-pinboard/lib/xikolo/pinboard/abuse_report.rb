# frozen_string_literal: true

class Xikolo::Pinboard::AbuseReport < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'abuse_reports'

  attribute :id, :uuid
  attribute :user_id, :uuid
  attribute :reportable_id, :uuid
  attribute :reportable_type, :string
  attribute :url, :string
  attribute :question_title, :string
  attribute :created_at, :string
end
