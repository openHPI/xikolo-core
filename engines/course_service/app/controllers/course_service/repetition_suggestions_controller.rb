# frozen_string_literal: true

module CourseService
class RepetitionSuggestionsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder
  respond_to :json
  def index
    # what results and corresponding items are possible repetition candidates:
    candidates = Result
      .joins(item: :section)
      .where(item: {sections: {course_id:}})
      .where(user_id:)
      .select(
        'dpoints as user_dpoints,
        item_id,
        ROW_NUMBER() OVER(
          PARTITION BY item_id ORDER BY dpoints DESC
        ) row_num'
      )
    candidates = candidates.where item: {content_type: content} if content.present?
    candidates = candidates.where item: {exercise_type: exercise} if exercise.present?

    # select items for each candidate:
    items = Item.from(
      Result.from(candidates, :results).where(row_num: 1)
        .joins(:item)
        .select('items.*,
          COALESCE((user_dpoints::float/max_dpoints::float)*100,0) AS percentage,
          user_dpoints'),
      :items
    ).available.reorder('percentage ASC')
    items.where! 'percentage < 80'
    items.limit! limit if limit.present?

    respond_with items
  end

  def decorate(res)
    RepetitionSuggestionDecorator.decorate_collection res
  end

  private

  def user_id
    params.require(:user_id)
  end

  def course_id
    params.require(:course_id)
  end

  def content
    params[:content_type]
  end

  def exercise
    params[:exercise_type]
  end

  def limit
    params[:limit]
  end
end
end
