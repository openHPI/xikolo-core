# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListClassifiers < Xikolo::API
        params do
          optional :cluster, type: String, desc: "The classifiers' cluster"
          optional :q, type: String, desc: 'Filter by a given string'
        end
        desc 'Returns list of all classifiers'
        get do
          header 'Cache-Control', 'public, max-age=900'

          classifiers = ::Course::Classifier.all

          if params['cluster'].present?
            classifiers = classifiers.where(cluster_id: params['cluster'])
          end

          if params['q'].present?
            classifiers = classifiers.query(params['q'])
          end

          present :classifiers, classifiers, with: Xikolo::Entities::Classifier
        end
      end
    end
  end
end
