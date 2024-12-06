# frozen_string_literal: true

class DocumentsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  respond_to :json

  rfc6570_params index: %i[course_id item_id language tag]
  def index
    documents = Document.all.not_deleted

    # Filter by course
    if params[:course_id].present?
      documents = documents.joins(:courses_documents)
        .where(courses_documents: {course_id: params[:course_id]})
    end

    # Filter by items
    if params[:item_id].present?
      documents = documents.joins(:documents_items)
        .where(documents_items: {item_id: params[:item_id]})
    end

    # Filter by language
    if params[:language].present?
      documents = documents.joins(:localizations)
        .where(document_localizations: {language: params[:language]})
    end

    # Filter by tag
    documents = documents.tagged_with(params[:tag]) if params[:tag].present?

    respond_with documents, embed:
  end

  def show
    document = Document.not_deleted.find params[:id]
    respond_with document, embed:
  end

  def create
    document = Document.create create_params
    respond_with document
  end

  def update
    document = Document.not_deleted.find params[:id]
    document.update(update_params)
    respond_with document
  end

  def destroy
    document = Document.find params[:id]
    document.soft_delete
    respond_with document
  end

  private

  def update_params
    params.permit(
      :title,
      :description,
      :public,
      :deleted,
      course_ids: [],
      item_ids: [],
      tags: []
    )
  end

  def create_params
    params.permit(
      :title,
      :description,
      :public,
      tags: [],
      course_ids: []
    )
  end

  def embed
    @embed ||= params[:embed].to_s.split(',').map(&:strip)
  end
end
