# frozen_string_literal: true

module CourseService
class ProgressesController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  MAIN_BONUS_POINTS = %w[main bonus].freeze
  MAIN_POINTS = %w[main].freeze

  respond_to :json
  def index
    # 0. verify params
    unless params[:course_id].present? && params[:user_id].present?
      return head(:not_found, content_type: 'text/plain')
    end

    user = params[:user_id]
    # 1. select base resources
    course = Course.find(params[:course_id])
    if course.legacy?
      sections = with_section_choices(course.sections.published.not_alternative)
      relevant_items = Item.course_order.all_available.joins(:section)
        .where(section_id: sections.map(&:id), sections: {course:})
    else
      relevant_items = Structure::UserItemsSelector.new(course.node, params[:user_id])
        .items(scope: Item.all_available).joins(:section)
      sections = Section.where(id: relevant_items.select(:section_id))
    end

    # 2. select submission results (exercise counts + dpoints) per section
    # and exercise type
    submitted_dpoints = Result.select('max(dpoints)')
      .where(user_id: user)
      .where('item_id = items.id')

    base1 = relevant_items.select(
      'items.id',
      'sections.position AS section_position',
      'sections.optional_section AS section_optional',
      'items.section_id',
      'items.exercise_type',
      'items.max_dpoints',
      'CASE WHEN submission_publishing_date > now()
        THEN submission_publishing_date
        ELSE NULL END AS withhold_submission_results',
      "(#{submitted_dpoints.to_sql}) submitted_dpoints"
    ).where.not(exercise_type: nil)

    base2 = Item.unscoped.from(base1.arel.as('base1')).select(
      '*',
      'case when submitted_dpoints IS NULL
        then NULL
        else withhold_submission_results end as submission_publishing_date',
      'case when withhold_submission_results IS NULL
        then submitted_dpoints
        else NULL end as graded_dpoints'
    ).arel.as('base2')

    submission_results = Item.unscope(:order).from(base2).select(
      'array_agg(base2.id) AS exercise_ids',
      'base2.section_id',
      'base2.section_optional',
      'base2.exercise_type',
      'count(base2.id) AS total_exercises',
      'count(base2.graded_dpoints) AS graded_exercises',
      'count(base2.submitted_dpoints) AS submitted_exercises',
      'coalesce(sum(base2.submitted_dpoints), 0) AS submitted_dpoints',
      'coalesce(sum(base2.graded_dpoints), 0) AS graded_dpoints',
      'coalesce(sum(base2.max_dpoints), 0) AS max_dpoints',
      'min(base2.submission_publishing_date) AS next_publishing_date',
      'max(base2.submission_publishing_date) AS last_publishing_date'
    ).group(
      'base2.section_id',
      'base2.section_position',
      'base2.section_optional',
      'base2.exercise_type'
    ).order('base2.section_position')

    # 3. select visit counts per section
    # will be aggregated in ruby from item's user_state

    # 4. select item meta data
    #   (id, title, content_type, exercise_type, user_state)
    # TODO but very like items?state_for=user_id
    items = relevant_items.user_state(params[:user_id])

    # 5. build sections + course progress options
    progresses = sections.map do |section|
      filter_for_section = ->(res) { res.section_id == section.id }
      Progress.new section,
        items.select(&filter_for_section),
        submission_results.select(&filter_for_section)
    end
    course_items, course_results =
      filter_results(progresses, items, submission_results)
    progresses << Progress.new(course, course_items, course_results)

    # 6. decorate
    respond_with progresses
  end

  def decorate(res)
    ProgressDecorator.decorate_collection res
  end

  private

  def with_section_choices(sections)
    sections = sections.sort_by(&:position)
    sections.map do |section|
      next section unless section.parent?

      choices = SectionChoice.where(section_id: section.id,
        user_id: params[:user_id])
      next section if choices.empty?

      section_choices = Section.where(id: choices.first.choice_ids)
      [section, section_choices.sort_by(&:position)]
    end.flatten
  end

  def filter_results(progresses, items, submission_results)
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
    filter_for_result = ->(res) { blacklist.include?(res.section_id) }
    [items, submission_results].map {|x| x.reject(&filter_for_result) }
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
