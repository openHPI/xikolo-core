# frozen_string_literal: true

module Course
  # The published items of a course the learner takes, with their state, in
  # course order: without the alternative sections they did not choose or that
  # were discarded, and without the content test branches they are not in.
  class LearnerItems
    # @param course [CourseService::Course]
    # @param user_id [String]
    # @param progresses [Array<Hash>] section progresses followed by the course
    #   progress, telling which alternative sections the learner takes
    def initialize(course, user_id, progresses)
      @course = course
      @user_id = user_id
      @progresses = progresses
    end

    # @param scope [ActiveRecord::Relation<CourseService::Item>] narrows down
    #   the items, e.g. to quizzes
    # @return [ActiveRecord::Relation<CourseService::Item>] with the learner's
    #   state (`.user_state` scope)
    def items(scope: CourseService::Item.all)
      items = scope.published
        .joins(:section).merge(CourseService::Section.published)
        .where(sections: {course_id: @course.id})

      items = if @course.legacy?
                items.where(section_id: taken_section_ids).course_order
              else
                CourseService::Structure::UserItemsSelector.new(@course.node, @user_id).items(scope: items)
              end
      items.user_state(@user_id)
    end

    private

    # In courses without a content tree, the progresses list the sections the
    # learner takes, i.e. without the alternatives they did not choose or that
    # were discarded.
    def taken_section_ids
      Array.wrap(@progresses)
        .select {|progress| progress['kind'] == 'section' && !progress['discarded'] }
        .pluck('resource_id')
    end
  end
end
