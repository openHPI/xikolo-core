# frozen_string_literal: true

module Course
  module LearnerProgress
    # The course sections, each listing its items with the learner's progress on them.
    class Sections < ApplicationComponent
      # @param progresses [Array<Hash>] the section progresses, followed by the course progress
      # @param course [CourseService::Course]
      # @param current_item_id [String, nil] the item the learner resumes the course at
      # @param locked_item_ids [Array<String>] the items the learner cannot work on
      # @param retakable_item_ids [Array<String>] the failed exams the learner can retake
      # @param exam_unlock_percentage [Integer, nil] the course progress (in percent)
      #   the learner needs to unlock the course exam, while it is still locked for them
      def initialize(progresses, course, current_item_id: nil, locked_item_ids: [], retakable_item_ids: [],
                     exam_unlock_percentage: nil)
        *section_progresses, _course_progress = progresses

        @sections = section_progresses.filter_map do |progress|
          section = SectionPresenter.new(progress, course, current_item_id:, locked_item_ids:, retakable_item_ids:,
            exam_unlock_percentage:)
          section if section.visible?
        end
      end
    end
  end
end
