# frozen_string_literal: true

class Xikolo::Pinboard::Vote < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'votes'

  attribute :id, :uuid
  attribute :value, :integer
  attribute :user_id, :uuid
  attribute :votable_id, :uuid
  attribute :votable_type, :string
  attribute :created_at, :string
  attribute :updated_at, :string
end
