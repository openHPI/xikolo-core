# frozen_string_literal: true

class Xikolo::Pinboard::Tag < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'tags'

  attribute :id, :uuid
  attribute :name, :string
  attribute :course_id, :uuid
  attribute :render, :boolean
  attribute :learning_room_id, :uuid
  attribute :tag, :string
end
