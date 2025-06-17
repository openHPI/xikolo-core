# frozen_string_literal: true

module Admin
  module Ajax
    class ClassifiersController < Abstract::AjaxController
      before_action :ensure_logged_in
      require_permission 'course.course.edit'
      respond_to? :json

      def index
        classifiers = ::Course::Classifier.all

        if params[:cluster].present?
          classifiers = classifiers.where(cluster_id: params[:cluster])
        end

        if params[:q].present?
          classifiers = classifiers.query(params[:q])
        end

        render json: serialize_classifiers(classifiers)
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
    end
  end
end
