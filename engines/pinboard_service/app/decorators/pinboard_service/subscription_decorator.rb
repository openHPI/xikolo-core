# frozen_string_literal: true

module PinboardService
class SubscriptionDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    attrs = basic

    if context[:with_question]
      attrs.merge!(
        question_title: model.question&.title,
        question_updated_at: model.question&.updated_at,
        course_id: model.question&.course_id,
        implicit_tags: model.question&.implicit_tags.to_a.map do |tag|
                         {name: tag.name,
                          referenced_resource: tag.referenced_resource}
                       end
      )
    end
    attrs.as_json(opts)
  end

  def basic
    {
      id:,
      user_id:,
      question_id:,
      created_at:,
    }
  end
end
end
