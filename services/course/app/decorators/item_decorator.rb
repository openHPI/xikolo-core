# frozen_string_literal: true

class ItemDecorator < ApplicationDecorator
  delegate_all
  def fields
    {
      id:,
      title:,
      start_date: start_date.try(:iso8601, 3),
      end_date: end_date.try(:iso8601, 3),
      content_type:,
      content_id:,
      exercise_type: model.exercise_type,
      max_points: model.max_dpoints.try(:/, 10.0),
      submission_deadline: model.effective_submission_deadline&.iso8601(3),
      submission_publishing_date: model.submission_publishing_date&.iso8601(3),
      section_id:,
      course_id: section.course.id,
      show_in_nav:,
      published: model.effective_published,
      position:,
      effective_start_date: model.effective_start_date&.iso8601(3),
      effective_end_date: model.effective_end_date&.iso8601(3),
      course_archived: model.course_archived,
      proctored: model.proctored,
      optional: model.optional,
      icon_type: model.icon_type,
      featured:,
      public_description:,
      open_mode: context[:raw] ? open_mode : open_mode_accessible?,
      time_effort:,
      required_item_ids:,
    }.tap do |attrs|
      attrs[:user_state] = model.user_state if model.user_state?
      unless context[:collection]
        attrs[:next_item_id] = model.higher_item_id(user_id: context[:user_id])
        attrs[:prev_item_id] = model.lower_item_id(user_id: context[:user_id])
      end
    end
  end

  def as_api_v1(opts)
    @opts = opts
    fields.tap do |attrs|
      attrs[:user_state] = model.user_state if model.user_state?

      if embed?('user_visit') && model.attributes.key?('visit_user_id')
        attrs[:user_visit] = if model.attributes['visit_user_id']
                               {
                                 user_id: model.attributes['visit_user_id'],
                                 updated_at:
                                   model.attributes['visit_updated_at'],
                               }
                             end
      end
    end.merge(urls)
  end

  def as_event(_opts = {})
    fields.merge(updated_at:).as_json
  end

  private

  def urls
    urls = {
      section_url: h.section_url(model.section_id),
      user_visit_url: h.item_user_visit_rfc6570.partial_expand(
        item_id: model.id
      ),
      results_url: h.item_results_url(item_id: model.id),
      statistics_url: h.item_statistics_url(item_id: model.id),
    }

    if model.graded?
      urls[:user_grade_url] = h.item_user_grade_rfc6570.partial_expand(
        item_id: model.id
      )
    end

    urls
  end

  def position
    return model.position unless context[:position_from_tree]

    model.node.lft
  end

  def embed?(obj)
    @opts&.key?(:embed) && @opts[:embed].include?(obj)
  end
end
