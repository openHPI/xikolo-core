# frozen_string_literal: true

##
# What goals can be achieved in this course based on its items?
#
# This takes into account content that will become *available* at a later time,
# but ignores the content that is not *published*.
#
class CourseGoals
  def initialize(course)
    @course = course
  end

  ##
  # The maximum number of visits of all non-optional items that belong to the
  # non-optional sections of a course. Alternative sections are ignored.
  #
  # This can be used, for example, to determine how many visits count towards
  # a Confirmation of Participation.
  #
  def max_visits
    @max_visits ||= begin
      relevant_sections = Section.published.mandatory.where(alternative_state: 'none')

      @course.items.published.mandatory
        .joins(:section).merge(relevant_sections)
        .count
    end
  end

  ##
  # The maximum number of points of all main exercise items that belong to the
  # sections of a course. Alternative sections are ignored.
  #
  # This can be used, for example, to determine how many points can be achieved
  # for a Record of Achievement.
  #
  def max_dpoints
    @max_dpoints ||= begin
      relevant_sections = Section.published.where(alternative_state: 'none')

      @course.items.published.where(exercise_type: 'main')
        .joins(:section).merge(relevant_sections)
        .sum(:max_dpoints)
    end
  end
end
