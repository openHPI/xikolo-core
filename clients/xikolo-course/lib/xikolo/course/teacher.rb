# frozen_string_literal: true

module Xikolo::Course
  class Teacher < Acfs::Resource
    service Xikolo::Course::Client, path: 'teachers'

    attribute :id, :uuid
    attribute :name, :string
    attribute :description, :dict
    attribute :picture_url, :string
  end
end
