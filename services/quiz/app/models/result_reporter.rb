# frozen_string_literal: true

class ResultReporter
  def initialize(quiz_id)
    @quiz_id = quiz_id
  end

  def report!(submission)
    return unless submission.submitted

    course_api.rel(:result).put(
      {
        user_id: submission.user_id,
        item_id: item['id'],
        points: submission.points,
      },
      params: {id: submission.id}
    ).value!
  end

  private

  def item
    @item ||= course_api.rel(:items).get({content_id: @quiz_id}).value!.first
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
