# frozen_string_literal: true

class GroupsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    respond_with Group.all
  end

  def show
    respond_with Group.find_by! show_params
  end

  def create
    ActiveRecord::Base.transaction do
      group = Group.create!

      Array(params[:participants]).each do |participant_id|
        Participant.find(participant_id).update! group:
      end

      respond_with group
    end
  end

  private

  def show_params
    params.permit :id
  end
end
