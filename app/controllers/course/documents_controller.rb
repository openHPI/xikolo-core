# frozen_string_literal: true

class Course::DocumentsController < Abstract::FrontendController
  include CourseContextHelper
  include DocumentHelper

  before_action do
    raise AbstractController::ActionNotFound unless Xikolo.config.beta_features['documents']
  end
  before_action :load_section_nav, only: :index
  before_action :ensure_logged_in

  inside_course only: %i[index show]

  def index
    @document_list = course_api.rel(:documents).get(
      {
        course_id: the_course.id,
        tag: params[:tag],
        language: params[:language],
      }.compact
    ).value!
    @course_documents = course_api.rel(:documents).get(course_id: the_course.id).value!
  end

  def show
    @document = course_api.rel(:document).get(id: params[:id], embed: 'course_ids').value!
  end

  private

  def request_course
    Xikolo::Course::Course.find(params[:id])
  end

  def auth_context
    the_course.context_id
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
