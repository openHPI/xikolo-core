# frozen_string_literal: true

class TagsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # GET /tags
  # GET /tags.xml
  def index
    tags = if params[:question_id] && Question.exists?(params[:question_id])
             if params[:type]
               Question.find(params[:question_id]).tags.order('name').where type: params[:type]
             else
               Question.find(params[:question_id]).tags.order('name')
             end
           elsif params[:course_id]
             if (params[:type] == 'ImplicitTag') && (params[:referenced_resource] || params[:name])
               find_or_create_implicit_tag
             elsif (params[:type] == 'ExplicitTag') && params[:name]
               find_or_create_explicit_tag
             elsif params[:type]
               tags_belonging_to_pinboard_resource.where type: params[:type]
             else
               tags_belonging_to_pinboard_resource
             end
           elsif params[:all]
             Tag.limit(nil).where type: params[:type]
           else
             []
           end

    respond_with tags
  end

  # GET /tags/1
  # GET /tags/1.xml
  def show
    respond_with Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.xml
  def create
    respond_with Tag.create(tag_params)
  end

  def max_per_page
    1000
  end

  private

  def tag_params
    params.permit(:name, :course_id, :type, :referenced_resource)
  end

  def tags_belonging_to_pinboard_resource
    if params[:name]
      Tag.by_name(params[:name]).where(course_id:)
    else
      offset = params['offset'] || 0
      if params['q'].nil?
        Tag.where(course_id:).offset(offset).order('name')
      else
        search_tag_by_name_like(offset)
      end
    end
  end

  def search_tag_by_name_like(offset)
    ExplicitTag
      .where('name ILIKE ?', "%#{params[:q]}%")
      .where(course_id:)
      .offset(offset)
  end

  def find_or_create_explicit_tag
    tag = begin
      ExplicitTag
        .by_name(params[:name])
        .where(course_id:)
        .first_or_create!(name: params[:name])
    rescue ActiveRecord::RecordNotUnique
      ExplicitTag.by_name(params[:name]).find_by(course_id:)
    end

    ExplicitTagDecorator.decorate_collection([tag])
  end

  def find_or_create_implicit_tag
    conditions = {course_id:}
    conditions = conditions.merge(referenced_resource: params[:referenced_resource]) if params[:referenced_resource]

    tag = begin
      ImplicitTag
        .by_name(params[:name])
        .where(conditions)
        .first_or_create!(name: params[:name])
    rescue ActiveRecord::RecordNotUnique
      ImplicitTag.by_name(params[:name]).find_by(conditions)
    end

    ImplicitTagDecorator.decorate_collection([tag])
  end

  def type_to_render
    params['type'] == 'ExplicitTag'
  end

  def course_id
    params[:course_id].nil? ? params[:question][:course_id] : params[:course_id]
  end
end
