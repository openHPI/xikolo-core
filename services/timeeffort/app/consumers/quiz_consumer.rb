# frozen_string_literal: true

class QuizConsumer < Msgr::Consumer
  def question_changed
    return unless Xikolo.config.timeeffort['enabled']
    return if payload[:quiz_id].blank?

    schedule_job payload.fetch(:quiz_id)
  end

  def answer_changed
    return unless Xikolo.config.timeeffort['enabled']
    return if payload[:question_id].blank?

    question = Xikolo.api(:quiz).value!
      .rel(:question)
      .get({id: payload.fetch(:question_id)})
      .value!

    schedule_job question['quiz_id']
  rescue Restify::ClientError => e
    # Do not fail if Question for Answer does not exist anymore
    raise unless e.code == 404
  end

  private
  def schedule_job(quiz_id)
    return if quiz_id.blank?

    item = Item.find_by! content_id: quiz_id

    # Ignore automatic updates of items with not supported content type
    if item.calculation_supported?
      TimeEffortJob.create!(item_id: item.id).schedule
    end
  rescue ActiveRecord::RecordNotFound
    # Do not fail if Item does not exist
  end
end
