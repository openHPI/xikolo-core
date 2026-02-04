# frozen_string_literal: true

module CourseService
class ChannelsCourse < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = 'channels_courses'

  belongs_to :course, class_name: 'CourseService::Course'
  belongs_to :channel, class_name: 'CourseService::Channel'
end
end
