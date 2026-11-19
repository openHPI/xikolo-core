# frozen_string_literal: true

module CourseService
class Progresses # rubocop:disable Layout/IndentationWidth
  MAIN_BONUS_POINTS = %w[main bonus].freeze
  MAIN_POINTS = %w[main].freeze

  def initialize(course, user)
    @course = course
    @user = user
  end

  def to_a
    # 1. select base resources
    if course.legacy?
      sections = with_section_choices(course.sections.published.not_alternative)
      relevant_items = Item.course_order.all_available.joins(:section)
        .where(section_id: sections.map(&:id), sections: {course:})
    else
      relevant_items = Structure::UserItemsSelector.new(course.node, user)
        .items(scope: Item.all_available).joins(:section)
      sections = Section.where(id: relevant_items.select(:section_id))
    end

    # 2. select the submission results, only needed to rank alternative sections
    submission_results = sections.any?(&:parent?) ? submission_results_for(relevant_items) : []

    # 3. select the items with the user's state (visits are counted from it)
    items = relevant_items.user_state(user)

    # 4. build sections + course progress
    progresses = sections.map do |section|
      filter_for_section = ->(res) { res.section_id == section.id }
      Progress.new section,
        items.select(&filter_for_section),
        submission_results.select(&filter_for_section)
    end
    progresses << Progress.new(course, course_items(progresses, items), [])
  end

  private

  attr_reader :course, :user

  def with_section_choices(sections)
    sections = sections.sort_by(&:position)
    sections.map do |section|
      next section unless section.parent?

      choices = SectionChoice.where(section_id: section.id,
        user_id: user)
      next section if choices.empty?

      section_choices = Section.where(id: choices.first.choice_ids)
      [section, section_choices.sort_by(&:position)]
    end.flatten
  end

  # The user's best submitted points per section and exercise type, with the
  # maximum points to achieve
  def submission_results_for(relevant_items)
    submitted_dpoints = Result.select('max(dpoints)')
      .where(user_id: user)
      .where('item_id = items.id')

    exercises = relevant_items.select(
      'items.section_id',
      'items.exercise_type',
      'items.max_dpoints',
      "(#{submitted_dpoints.to_sql}) submitted_dpoints"
    ).where.not(exercise_type: nil)

    Item.from(exercises.arel.as('exercises')).select(
      'exercises.section_id',
      'exercises.exercise_type',
      'coalesce(sum(exercises.submitted_dpoints), 0) AS submitted_dpoints',
      'coalesce(sum(exercises.max_dpoints), 0) AS max_dpoints'
    ).group('exercises.section_id', 'exercises.exercise_type')
  end

  # Marks the best of the alternative sections the user chose. The items of
  # the other alternatives do not count towards the course progress.
  def course_items(progresses, items)
    blacklist = []
    progresses.each do |progress|
      next unless progress.parent_section?

      alternatives = progresses.select do |p|
        p.parent_id == progress.resource_id
      end
      next if alternatives.empty?

      # mark best alternative:
      best_alternative(alternatives).best_alternative = true
      blacklist += filter_out_best_alternative(alternatives).map(&:resource_id)
    end
    items.reject {|item| blacklist.include?(item.section_id) }
  end

  def alternatives_rating(alternatives)
    @alternatives_rating ||= {}
    @alternatives_rating[alternatives] ||= alternatives.sort_by do |a|
      # calculate relevant user and maximal points:
      user_dpoints = a.results.select do |r|
        MAIN_BONUS_POINTS.include? r.exercise_type
      end.sum(&:submitted_dpoints)
      max_dpoints = a.results.select do |r|
        MAIN_POINTS.include? r.exercise_type
      end.sum(&:max_dpoints)

      # calculate relative values for comparision:
      point_permillage = if max_dpoints.positive?
                           [user_dpoints * 1000 / max_dpoints, 1000].min
                         else
                           1000
                         end
      visit_permillage = if a.visited_total.positive?
                           [a.visited_user * 1000 / a.visited_total, 1000].min
                         else
                           1000
                         end

      # return array to compare this alternative with
      # a different one:
      [
        point_permillage,
        user_dpoints.zero? ? -max_dpoints : max_dpoints,
        visit_permillage,
        a.visited_user.zero? ? -a.visited_total : a.visited_total,
      ]
    end
  end
  # rubocop:enable all

  def filter_out_best_alternative(alternatives)
    alternatives_rating(alternatives)[0...-1]
  end

  def best_alternative(alternatives)
    alternatives_rating(alternatives).last
  end
end
end
