# frozen_string_literal: true

module CourseService
class DocumentLocalizationsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  respond_to :json

  rfc6570_params index: [:document_id]

  def index
    document_localization = DocumentLocalization.all.not_deleted

    # Filter by document
    if params[:document_id]
      document_localization.where! document_id: params[:document_id]
    end
    respond_with document_localization
  end

  def create
    document_localization = DocumentLocalization.create \
      document_localization_params
    respond_with document_localization
  end

  def show
    document_localization = DocumentLocalization.not_deleted.find params[:id]
    respond_with document_localization
  end

  def update
    document_localization = DocumentLocalization.not_deleted.find params[:id]
    document_localization.update(document_localization_params)
    respond_with document_localization
  end

  def destroy
    document_localization = DocumentLocalization.find params[:id]
    document_localization.soft_delete
    respond_with document_localization
  end

  private

  def document_localization_params
    params.permit(
      :title,
      :description,
      :language,
      :deleted,
      :file_upload_id,
      :document_id
    )
  end
end
end
