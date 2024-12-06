# frozen_string_literal: true

class SectionChoicesController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    choices = SectionChoice.all
    choices.where! user_id: params[:user_id] if params[:user_id]
    choices.where! section_id: params[:section_id] if params[:section_id]
    respond_with choices
  end

  def create
    sc = SectionChoice.find_or_initialize_by(user_id: params[:user_id],
      section_id: params[:section_id])
    choice_id = params[:chosen_section_id]
    unless sc.choice_ids.include?(choice_id)
      sc.choice_ids << choice_id
      sc.save!
    end
    respond_with({}, {location: ''})
  end
end
