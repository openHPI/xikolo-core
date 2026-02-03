# frozen_string_literal: true

module Course
  class ChannelsCourse < ApplicationRecord
    self.table_name = 'channels_courses'

    belongs_to :course, class_name: 'Course::Course'
    belongs_to :channel, class_name: 'Course::Channel'
  end
end
