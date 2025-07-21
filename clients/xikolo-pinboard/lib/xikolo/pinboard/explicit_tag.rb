# frozen_string_literal: true

module Xikolo::Pinboard
  class ExplicitTag < Xikolo::Pinboard::Tag
    service Xikolo::Pinboard::Client, path: 'explicit_tags'

    attribute :id, :uuid
    attribute :name, :string
    attribute :course_id, :uuid
    attribute :type, :string
  end
end
