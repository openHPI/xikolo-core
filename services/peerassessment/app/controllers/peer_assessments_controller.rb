# frozen_string_literal: true

class PeerAssessmentsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    assessments = PeerAssessment.includes(:files).where peer_assessment_params
    respond_with assessments
  end

  def show
    decoration_context[:raw] = params[:raw]
    respond_with PeerAssessment.find params[:id]
  end

  def create
    assessment = PeerAssessment.new id: SecureRandom.uuid
    respond_with PeerAssessment::Store.call(assessment, create_params)
  end

  def update
    assessment = PeerAssessment.find params[:id]

    if params.key? :gallery_entries
      assessment.gallery_entries_will_change!
      assessment.gallery_entries = params[:gallery_entries]
    end

    respond_with PeerAssessment::Store.call(assessment, update_params)
  end

  def destroy
    # TBD
  end

  ### Decorator methods ###

  def decoration_context
    @decoration_context ||= {}
  end

  private

  def peer_assessment_params
    params.permit %i[
      id
      user_id
      course_id
      is_team_assessment
    ]
  end

  def create_params
    params.permit %i[
      item_id
      course_id
      title
      instructions
      allowed_file_types
      grading_hints
      allowed_attachments
      allow_gallery_opt_out
      usage_disclaimer
      max_file_size
      is_team_assessment
    ]
  end

  def update_params
    params.permit %i[
      item_id
      instructions
      max_file_size
      allowed_file_types
      grading_hints
      allowed_attachments
      allow_gallery_opt_out
      usage_disclaimer
      instructions
      title
      is_team_assessment
    ]
  end
end
