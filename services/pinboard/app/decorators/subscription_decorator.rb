# frozen_string_literal: true

class SubscriptionDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    attrs = basic

    if context[:with_question]
      attrs.merge!(
        question_title: model.question&.title,
        question_updated_at: model.question&.updated_at,
        course_id: model.question&.course_id,
        learning_room_id: model.question&.learning_room_id,
        implicit_tags: (model.question&.implicit_tags.to_a || []).map do |tag|
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
