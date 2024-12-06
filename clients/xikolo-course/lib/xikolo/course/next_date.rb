# frozen_string_literal: true

module Xikolo::Course
  class NextDate < Acfs::Resource
    service Xikolo::Course::Client, path: 'next_dates'

    # resource info itself (course, section, item)
    attribute :resource_id, :uuid
    attribute :resource_type, :string
    # course info
    attribute :course_id, :uuid
    attribute :course_code, :string
    attribute :course_title, :string

    # event data itself
    attribute :date, :date_time
    attribute :kind, :string
    attribute :title, :string
  end
end
