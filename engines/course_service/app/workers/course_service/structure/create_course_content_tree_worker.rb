# frozen_string_literal: true

module CourseService
##
# This worker allows to create the course content tree for a course that
# does not have corresponding `::Structure` nodes yet. This eases the
# migration when switching to the new course content tree for all courses.

# this feature is currently not supported and the worker is unreliable
#
module Structure # rubocop:disable Layout/IndentationWidth
  class CreateCourseContentTreeWorker
    include Sidekiq::Job

    sidekiq_options retry: false

    def perform(course)
      course = Course.by_identifier(course).take
      raise 'Course not found' unless course

      if course.node.present?
        raise 'The course content tree already exists.'
      end

      course.create_node!

      # Create the sections and their items in the correct order.
      course.sections.includes(:items).order(position: :asc).each do |section|
        section.create_node!(course:, parent: course.node)

        section.items.order('items.position ASC').each do |item|
          item.create_node!(course:, parent: section.node)
        end
      end
    end
  end
end
end
