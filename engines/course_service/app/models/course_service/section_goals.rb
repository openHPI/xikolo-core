# frozen_string_literal: true

module CourseService
##
# What goals can be achieved in this section based on its items?
#
# This takes into account content that will become *available* at a later time,
# but ignores the content that is not *published*.
#
class SectionGoals # rubocop:disable Layout/IndentationWidth
  def initialize(section, user_id)
    @section = section
    @user_id = user_id
  end

  # How many visits can be achieved by this user for this section?
  def max_visits
    @max_visits ||= relevant_items
      .published.mandatory
      .count
  end

  # How many points can be achieved by this user for this section?
  # This takes into account homework and exams, but no bonus tasks.
  def max_dpoints
    @max_dpoints ||= relevant_items
      .published.where(exercise_type: 'main')
      .sum(:max_dpoints)
  end

  def relevant_items
    @relevant_items ||= if @section.course.legacy?
                          @section.items
                        else
                          Structure::UserItemsSelector.new(@section.node, @user_id).items
                        end
  end
end
end
