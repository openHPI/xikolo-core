# frozen_string_literal: true

module CourseService
class TeachersController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: %i[course query]
  def index
    teachers = Teacher.all
    teachers = teachers.for_course(params[:course]) if params[:course]
    teachers = teachers.where(user_id: params[:user_id]) if params[:user_id]
    teachers = teachers.filter_by_query(params[:query]) if params[:query]
    teachers = teachers.order('lower(name) asc') if params[:sort] == 'name'
    respond_with teachers
  end

  def create
    teacher = Teacher.new create_teacher_params
    if teacher.valid?
      if params[:picture_uri].present?
        teacher.upload_via_uri(params[:picture_uri])
      else
        teacher.upload_via_id(params[:picture_upload_id])
      end
      teacher.save if teacher.errors.empty?
    end
    respond_with teacher
  end

  def show
    respond_with Teacher.find params[:id]
  end

  def update
    teacher = Teacher.find(params[:id])
    teacher.assign_attributes update_teacher_params

    if teacher.valid?
      if params.key?(:picture_uri)
        teacher.upload_via_uri(params[:picture_uri])
      else
        teacher.upload_via_id(params[:picture_upload_id])
      end
      teacher.save if teacher.errors.empty?
    end
    respond_with teacher
  end

  private

  def update_teacher_params
    params.permit(:name, description: {})
  end

  def create_teacher_params
    params[:user_id] = params[:id] unless params.key?(:user_id)
    params.permit(:id, :user_id, :name, description: {})
  end
end
end
