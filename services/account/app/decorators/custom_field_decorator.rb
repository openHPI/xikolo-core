# frozen_string_literal: true

class CustomFieldDecorator < ApplicationDecorator
  delegate_all

  DEFAULT = %i[
    id
    name
    type
    title
    required
    default_values
    available_values
  ].freeze

  def as_json(opts = {})
    export DEFAULT, optional_fields, **opts
  end

  def optional_fields
    [].tap do |fields|
      fields << :values if context[:user_values]
      fields << :aggregation if context[:histograms]
    end
  end

  def title
    {en: model.title}
  end

  def required
    required?
  end

  def available_values
    model.values
  end

  def values
    value = context[:user_values].find {|f| f.custom_field_id == id }

    if value&.values
      value.values
    else
      default_values
    end
  end

  def aggregation
    context[:histograms][model] || {}
  end
end
