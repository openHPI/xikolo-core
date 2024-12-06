# frozen_string_literal: true

class UserVotesController < ApplicationController
  responders Responders::DecorateResponder

  respond_to :json

  # PUT/PATCH /posts/:post_id/user_votes/:user_id
  def update
    respond_with post.vote(params[:value], user_id:)
  end

  private

  def post
    @post ||= Post.find params[:post_id]
  end

  def user_id
    params.require :id
  end
end
