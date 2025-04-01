# frozen_string_literal: true

class Admin::DocumentLocalizationsController < Abstract::FrontendController
  include DocumentHelper

  respond_to :json

  before_action do
    raise AbstractController::ActionNotFound unless Xikolo.config.beta_features['documents']
  end

  def new
    authorize! 'course.document.manage'

    @document_url = document_path(params[:document_id])
    file_upload!
  end

  def edit
    authorize! 'course.document.manage'

    localization = Xikolo.api(:course).value!.rel(:document_localization).get({id: params[:id]}).value!
    @localization = Localization.new(localization.title,
      localization.description,
      localization.file_url,
      localization.language,
      localization.deleted,
      localization.document_id,
      localization.id)
    @document_url = localization.document_url
    file_upload!
  end

  def create
    authorize! 'course.document.manage'

    add_localization
  end

  def update
    authorize! 'course.document.manage'

    update_localization
  end

  def destroy
    authorize! 'course.document.manage'

    delete_localization
  end
end
