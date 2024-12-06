# frozen_string_literal: true

class TagsController < ApplicationController
  include LearningRoomIntegrationHelper

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
           elsif params[:course_id] || params[:learning_room_id]
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
    @tag = Tag.find(params[:id])
    respond_with(@tag)
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Tag.create tag_params
    respond_with @tag
  end

  def max_per_page
    1000
  end

  private

  def tag_params
    my_params = params.permit(:name, :course_id, :learning_room_id, :type, :referenced_resource)
    my_params[:course_id] = nil if my_params[:learning_room_id]
    my_params
  end

  def tags_belonging_to_pinboard_resource
    belonging_resource = belonging_resource_hash
    if params[:name]
      Tag.by_name(params[:name]).where(belonging_resource)
    else
      offset = params['offset'] || 0
      if params['q'].nil?
        Tag.where(belonging_resource).offset(offset).order('name')
      else
        search_tag_by_name_like belonging_resource, offset
      end
    end
  end

  def search_tag_by_name_like(belonging_resource, offset)
    resource_key   = belonging_resource.first[0]
    resource_value = belonging_resource.first[1]
    ExplicitTag
      .where('name ILIKE ?', "%#{params[:q]}%")
      .where(resource_key => resource_value)
      .offset(offset)
  end

  def find_or_create_explicit_tag
    tag = begin
      ExplicitTag
        .by_name(params[:name])
        .where(belonging_resource_hash)
        .first_or_create!(name: params[:name])
    rescue ActiveRecord::RecordNotUnique
      ExplicitTag.by_name(params[:name]).find_by(belonging_resource_hash)
    end

    ExplicitTagDecorator.decorate_collection([tag])
  end

  def find_or_create_implicit_tag
    conditions = belonging_resource_hash
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
end
