# frozen_string_literal: true

module PinboardService
class TopicsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::PaginateResponder

  respond_to :json

  # GET /topics
  def index
    return respond_with Question.none if params[:item_id].blank?

    respond_with item_tag.questions.undeleted.unblocked
  end

  # POST /topics
  def create
    respond_with Commentable::Store.call(Question.new(id: SecureRandom.uuid), topic_params)
  end

  # GET /topics/:id
  def show
    respond_with topic, embed:
  end

  def decorate(res)
    if res.is_a? ActiveRecord::Relation
      TopicDecorator.decorate_collection res
    else
      TopicDecorator.decorate res
    end
  end

  private

  def topic
    @topic ||= Question
      .includes(:tags, :comments, answers: :comments)
      .find(params[:id])
  end

  def item_tag
    ImplicitTag.find_or_initialize_by(
      referenced_resource: 'Xikolo::Course::Item', name: params[:item_id]
    )
  end

  def embed
    params[:embed].to_s.split(',')
  end

  def topic_params
    params.permit(
      :title, :author_id, :course_id, :item_id,
      meta: [:video_timestamp], tags: []
    ).tap do |p|
      p[:text] = params.require(:first_post)[:text]
    end
  end
end
end
