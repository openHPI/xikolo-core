# frozen_string_literal: true

class PostsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json, :msgpack

  # This focuses on exposing the announcements published on the site ("News").
  # It does not include announcements that have been published via email.
  def index
    posts = News.includes(:translations)
      .order(publish_at: :desc)
      .for_groups(user: params[:user_id])

    posts = posts.where(publish_at: ...Time.zone.now) if published_posts?

    respond_with posts
  end

  def decorate(res)
    NewsDecorator.decorate_collection res, context: decoration_context
  end

  def decoration_context
    @decoration_context ||= params.permit(:language)
  end

  private

  def published_posts?
    params[:published] == 'true'
  end
end
