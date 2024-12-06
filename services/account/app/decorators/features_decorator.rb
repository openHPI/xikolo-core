# frozen_string_literal: true

class FeaturesDecorator < Draper::CollectionDecorator
  def as_json(opts = {})
    object.each_with_object({}) do |feature, object|
      object[feature.name] = feature.value
    end.as_json(opts)
  end
end
