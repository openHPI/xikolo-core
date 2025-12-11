# frozen_string_literal: true

module QuizService
module PointsProcessor # rubocop:disable Layout/IndentationWidth
  def update_item_max_points(quiz_id)
    questions = Question.where(quiz_id:)
    sum_points = 0
    questions.each do |q|
      sum_points += q.points
    end

    course_api = Xikolo.api(:course).value!
    items = course_api.rel(:items).get({content_id: quiz_id}).value!

    unless items.empty?
      item = items.first
      course_api.rel(:item).patch(
        {max_points: sum_points == 0 ? nil : sum_points},
        params: {id: item['id']}
      ).value!
    end
  end
end
end
