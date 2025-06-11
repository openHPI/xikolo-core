# frozen_string_literal: true

class ClassifiersController < ApplicationController
  before_action :ensure_logged_in

  def show
    classifiers = ::Course::Classifier.all

    if params[:cluster].present?
      classifiers = classifiers.where(cluster_id: params[:cluster])
    end

    if params[:q].present?
      classifiers = classifiers.query(params[:q])
    end

    render json: {classifiers: serialize_classifiers(classifiers)}, status: :ok
  end

  private

  def serialize_classifiers(classifiers)
    classifiers.map do |classifier|
      {
        id: classifier.id,
        title: classifier.title,
        cluster_id: classifier.cluster_id,
        translations: classifier.translations,
      }.compact
    end
  end

  def ensure_logged_in
    return true if current_user.logged_in?

    head :unauthorized
  end
end
