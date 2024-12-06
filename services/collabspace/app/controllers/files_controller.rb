# frozen_string_literal: true

require 'api_responder'
require 'errors'

class FilesController < ApplicationController
  self.responder = ::APIResponder

  respond_to :json

  def index
    respond_with collab_space.files
  end

  def create
    file = collab_space.files.new new_file_params

    UploadedFile.transaction do
      file.save!
      file.process_upload! params.require(:upload_uri)
    end

    respond_with file, location: false
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  rescue Errors::InvalidUpload => e
    render status: :unprocessable_entity, json: e
  end

  def show
    respond_with UploadedFile.find(params[:id])
  end

  def destroy
    UploadedFile.find(params[:id]).destroy
    head :ok, content_type: 'text/plain'
  end

  private

  def new_file_params
    params.permit(:creator_id, :title, :description)
  end

  def collab_space
    @collab_space ||= CollabSpace.find params.require(:collab_space_id)
  end
end
