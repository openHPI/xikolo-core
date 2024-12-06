# frozen_string_literal: true

class DocumentLocalizationDecorator < ApplicationDecorator
  delegate_all

  def fields
    {
      id: model.id,
      title: model.title,
      description: model.description,
      language: model.language,
      revision: model.revision,
      document_id: model.document_id,
      deleted: model.deleted,
      file_url: model.file_url,
    }
  end

  def as_api_v1(*)
    fields.merge(
      url: h.document_localization_path(model),
      document_url: h.document_path(model.document_id)
    )
  end

  def as_event
    fields.as_json
  end
end
