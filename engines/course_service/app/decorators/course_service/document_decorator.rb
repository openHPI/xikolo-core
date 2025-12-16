# frozen_string_literal: true

module CourseService
class DocumentDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def fields
    {
      id: model.id,
      title: model.title,
      description: model.description,
      tags: model.tags,
      public: model.public,
      localizations: model.localizations.map do |loc|
        loc.decorate.as_json(api_version: 1)
      end,
    }
  end

  def as_api_v1(opts = {})
    @opts = opts
    fields.tap do |attrs|
      attrs[:course_ids] = model.courses.pluck(:id) if embed?('course_ids')
      attrs[:items] = model.items.pluck(:id) if embed?('items')
    end.merge(
      url: h.document_path(model),
      localizations_url: h.document_document_localizations_path(model)
    )
  end

  def as_event
    fields.as_json
  end

  def embed?(obj)
    @opts&.key?(:embed) && @opts[:embed].include?(obj)
  end
end
end
