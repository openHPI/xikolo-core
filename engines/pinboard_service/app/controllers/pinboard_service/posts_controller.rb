# frozen_string_literal: true

module PinboardService
class PostsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder

  respond_to :json

  # GET /posts/:id
  def show
    respond_with post
  end

  # DELETE /posts/:id
  def destroy
    respond_with post.destroy
  end

  private

  def post
    @post ||= Post.find params[:id]
  end
end
end
