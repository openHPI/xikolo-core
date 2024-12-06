# frozen_string_literal: true

module Xikolo::Course
  class SectionChoice < Acfs::Resource
    service Xikolo::Course::Client, path: '/section_choices'

    attribute :section_id, :uuid
    attribute :user_id, :uuid
    attribute :choice_ids, :list
  end
end
