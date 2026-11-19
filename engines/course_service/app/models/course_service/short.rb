# frozen_string_literal: true

module CourseService
  class Short < ApplicationRecord
    include Translatable

    self.table_name = :shorts

    has_one_attached :video

    translated_field :title, required: :any
    translated_field :description, required: false

    enum :status, {
      preparation: 'preparation',
      active: 'active',
      archived: 'archived',
    }

    class << self
      def for_course(course)
        where(course_id: course.id)
      end

      def active
        where(status: 'active')
      end

      def preparation
        where(status: 'preparation')
      end

      def archived
        where(status: 'archived')
      end

      def with_video
        where.not(bunny_video_id: nil)
      end
    end

    belongs_to :course, class_name: 'CourseService::Course'
    has_many :channels, through: :course
    has_many :classifiers, through: :course
  end
end
