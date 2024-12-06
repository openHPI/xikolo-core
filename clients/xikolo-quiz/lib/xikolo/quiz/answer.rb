# frozen_string_literal: true

class Xikolo::Quiz::Answer < Acfs::Resource
  service Xikolo::Quiz::Client, path: 'answers'

  attribute :id, :uuid
  attribute :question_id, :uuid
  attribute :text, :string
  attribute :comment, :string
  attribute :position, :integer
  attribute :correct, :boolean, default: false
  attribute :type, :string
end
