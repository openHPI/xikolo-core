# frozen_string_literal: true

module Xikolo::Pinboard
  class ImplicitTag < Xikolo::Pinboard::Tag
    service Xikolo::Pinboard::Client, path: 'implicit_tags'

    attribute :id, :uuid
    attribute :name, :string
    attribute :course_id, :uuid
    attribute :referenced_resource, :string
    attribute :type, :string
  end
end
