# frozen_string_literal: true

class RichtextDecorator < ApplicationDecorator
  delegate :errors

  def fields
    {
      id: object.id,
      text:,
    }
  end

  def as_api_v1(_opts)
    fields.as_json
  end

  def as_event(_opts)
    fields.as_json
  end

  def text
    Xikolo::S3.externalize_file_refs(object.text, public: true)
  end
end
