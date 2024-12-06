# frozen_string_literal: true

module Xikolo::Course
  class Progress < Acfs::Resource
    service Xikolo::Course::Client, path: '/progresses'

    attribute :resource_id, :uuid
    attribute :kind, :string
    attribute :visits, :dict
    attribute :items, :list
    attribute :title, :string
    attribute :description, :string
    attribute :available, :boolean
    attribute :optional, :boolean
    attribute :parent, :boolean
    attribute :alternative_state, :string
    attribute :discarded, :boolean
    attribute :selftest_exercises, :dict
    attribute :main_exercises, :dict
    attribute :bonus_exercises, :dict
    attribute :required_section_ids, :list
  end
end
