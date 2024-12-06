# frozen_string_literal: true

class VotesController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    if params[:votable_type].nil?
      respond_with Vote.all
    elsif params[:votable_id].nil?
      respond_with Vote.where(
        votable_type: params[:votable_type]
      )
    elsif params[:user_id].nil?
      respond_with Vote.where(
        votable_id: params[:votable_id],
        votable_type: params[:votable_type]
      )
    else
      respond_with Vote.where(
        votable_id: params[:votable_id],
        votable_type: params[:votable_type],
        user_id: params[:user_id]
      )
    end
  end

  def show
    @vote = Vote.find(params[:id])
    respond_with(@vote)
  end

  def create
    votable = nil

    if vote_params[:votable_type].casecmp('question').zero?
      votable = Question.find(vote_params[:votable_id])
    elsif vote_params[:votable_type].casecmp('answer').zero?
      votable = Answer.find(vote_params[:votable_id])
    end

    @vote = Vote.new

    unless votable.nil?
      @vote.value = vote_params[:value]
      @vote.votable = votable
      @vote.user_id = vote_params[:user_id]

      # we do not send the votable_id here, since it would also require us to
      # send votable_type
      @vote.save
    end

    respond_with(@vote)
  end

  def update
    @vote = Vote.find(params[:id])
    @vote.update value: params[:value]
    respond_with @vote
  end

  def destroy
    @vote = Vote.find(params[:id])
    @vote.destroy
    respond_with(@vote)
  end

  private
  def vote_params
    params.require(%i[votable_id votable_type])
    params.permit(:value, :user_id, :votable_id, :votable_type)
  end
end
