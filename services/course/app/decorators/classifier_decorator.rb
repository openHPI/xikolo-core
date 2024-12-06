# frozen_string_literal: true

class ClassifierDecorator < ApplicationDecorator
  delegate_all

  def as_api_v1(_opts)
    {
      id:,
      title:,
      cluster: cluster_id,
      courses: courses.collect(&:id),
      url: h.classifier_path(model),
    }
  end
end
