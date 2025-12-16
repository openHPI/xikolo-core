# frozen_string_literal: true

module CourseService
class SectionsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json
  def index
    sections = Section.all
    sections.where! course_id: params[:course_id] unless params[:course_id].nil?
    sections.where! published: params[:published] unless params[:published].nil?
    sections = sections.available unless params[:available].nil?
    sections.where! id: params[:id] if params[:id]
    sections.where! position: params[:position] if params[:position]
    if params[:parent_id]
      sections.where! parent_id: params[:parent_id]
    elsif !params[:include_alternatives]
      sections = sections.not_alternative
    end
    sections.includes! :course

    respond_with sections
  end

  def show
    respond_with Section.find params[:id]
  end

  def create
    section = Section.create section_params
    if params[:parent_id]
      Section.find(params[:parent_id])
        .update alternative_state: 'parent'
    end
    section.move_to_bottom
    respond_with section
  end

  def update
    section = Section.find(params[:id])
    section.update(section_params)
    respond_with section
  end

  def destroy
    section = Section.find(params[:id])

    return head :forbidden unless section.destroyable?

    respond_with Section::Destroy.call(section)
  end

  private

  def section_params
    permitted_params = params.permit(
      :title,
      :id,
      :description,
      :published,
      :start_date,
      :end_date,
      :course_id,
      :position,
      :optional_section,
      :format,
      :pinboard_closed,
      :alternative_state,
      :parent_id,
      required_section_ids: []
    )
    permitted_params.except :format
  end
end
end
