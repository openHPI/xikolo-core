# frozen_string_literal: true

class Admin::DocumentsController < Abstract::FrontendController
  include DocumentHelper

  respond_to :json

  before_action do
    raise AbstractController::ActionNotFound unless Xikolo.config.beta_features['documents']
  end

  def index
    authorize! 'course.document.manage'

    documents = course_api.rel(:documents).get(
      document_index_params.merge(embed: 'course_ids')
    )
    courses = course_api.rel(:courses).get(affilated: true, per_page: 250)
    document_tags = course_api.rel(:documents_tags).get

    @document_list = DocumentsListPresenter.build(
      documents.value!,
      courses.value!,
      document_tags.value!,
      document_index_params,
      view_context
    )
  end

  def show
    authorize! 'course.document.manage'

    @document = course_api.rel(:document).get(id: params[:id], embed: 'course_ids').value!
    @course_titles = preselected_courses(@document.course_ids).map(&:title)
  end

  def new
    authorize! 'course.document.manage'

    load_all_tags
    @is_new_document = true
    file_upload!
  end

  def edit
    authorize! 'course.document.manage'

    load_all_tags

    @is_new_document = false
    @document = course_api.rel(:document).get(id: params[:id], embed: 'course_ids').value!
    @selected_courses = preselected_courses @document.course_ids
  end

  def create
    authorize! 'course.document.manage'

    create_document
  end

  def update
    authorize! 'course.document.manage'

    update_document
  end

  def destroy
    authorize! 'course.document.manage'

    delete_document
  end

  private

  def preselected_courses(course_ids)
    course_ids.map do |course_id|
      course_api.rel(:course).get(id: course_id)
    end.filter_map(&:value)
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def document_index_params
    params.permit(:language, :tag, :course_id, :page).to_h
  end
end
