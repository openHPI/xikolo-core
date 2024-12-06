# frozen_string_literal: true

class NotesController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    respond_with Note.where index_params
  end

  def show
    respond_with Note.find params[:id]
  end

  def create
    respond_with Note.create!(create_params)
  end

  def update
    respond_with Note.find(params[:id]).update! update_params
  end

  def destroy
    respond_with Note.find(params[:id]).destroy
  end

  private

  def index_params
    params.permit :id, :subject_id, :subject_type, :updated_at, :created_at, :user_id
  end

  def update_params
    params.permit :text
  end

  def create_params
    params.permit :id, :subject_id, :subject_type, :text, :user_id
  end
end
