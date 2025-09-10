# frozen_string_literal: true

# rubocop:disable Rails/HelperInstanceVariable
# TODO: Get rid of this helper
module DocumentHelper
  Document = Struct.new(:title, :description, :tags, :course_ids, :public, :id, :language, :localizations) do
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    def persisted?
      true
    end

    def tag_array
      tags&.join(',')
    end
  end

  Localization = Struct.new(:title, :description, :file_url, :language, :deleted, :document_id, :id) do
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    def persisted?
      true
    end
  end

  def add_localization(document = nil)
    document ||= Xikolo.api(:course).value!.rel(:document).get({
      id: params[:document_id],
    }).value!
    document.rel(:localizations).post(create_localization_params).value!
    redirect_to documents_path
  end

  def update_localization
    update_params = update_localization_params
    localization = Xikolo.api(:course).value!.rel(:document_localization).get({
      id: params[:id],
    }).value!
    localization.rel(:self).patch(update_params).value!
    redirect_to localization.document_url
  end

  def delete_localization
    Xikolo.api(:course).value!.rel(:document_localization).delete({id: params[:id]}).value!
    redirect_to documents_path
  end

  def create_document
    @document = Xikolo.api(:course).value!.rel(:documents).post(create_document_params).value!
  rescue Restify::ClientError
    add_flash_message :error, t(:'flash.error.document.title_already_taken')
    @document = Document.new(
      create_document_params[:title],
      create_document_params[:description],
      create_document_params[:tags],
      create_document_params[:course_ids],
      create_document_params[:public],
      nil,
      create_localization_params[:language]
    )
    file_upload!
    render action: :new
  else
    add_localization(@document)
  end

  def update_document
    update_params = params[:document].permit(:title,
      :description,
      :public,
      course_ids: [],
      item_ids: [],
      tags: []).to_h
    update_params[:id] = params[:id]
    update_params[:tags]&.reject!(&:blank?)
    update_params[:course_ids]&.reject!(&:blank?)

    Xikolo.api(:course).value!.rel(:document).patch(update_params, params: {id: params[:id]}).value!
    redirect_to document_path(id: update_params[:id])
  end

  def delete_document
    Xikolo.api(:course).value!.rel(:document).delete({id: params[:id]}).value!
    redirect_to documents_path
  end

  def dropdown_index
    @documents = Xikolo.api(:course).value!.rel(:document).get.value!
  end

  def load_all_tags
    @all_tags = Xikolo.api(:course).value!.rel(:documents_tags).get.value!
  end

  def file_upload!
    @file_upload = FileUpload.new(
      purpose: :course_document,
      content_type: 'application/pdf'
    )
  end

  private

  def create_document_params
    create_params = params
      .require(:document)
      .permit(
        :title,
        :description,
        :public,
        item_ids: [],
        tags: [],
        course_ids: []
      )

    create_params[:tags]&.reject!(&:blank?)
    create_params[:item_ids]&.reject!(&:blank?)
    create_params[:course_ids]&.reject!(&:blank?)

    create_params.to_h
  end

  def create_localization_params
    params.require(:localization).permit(:title, :description, :language, :file_upload_id).to_h
  end

  def update_localization_params
    params.require(:localization).permit(
      :title,
      :description,
      :language,
      :file_upload_id
    ).to_h
  end
end
# rubocop:enable all
