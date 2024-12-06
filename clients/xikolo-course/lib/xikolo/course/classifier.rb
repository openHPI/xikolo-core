# frozen_string_literal: true

module Xikolo::Course
  class Classifier < Acfs::Resource
    service Xikolo::Course::Client, path: 'classifiers'

    attribute :id, :uuid
    attribute :title, :string
    attribute :description, :string
    attribute :cluster, :string
    attribute :url, :string
    attribute :courses, :list
  end
end
