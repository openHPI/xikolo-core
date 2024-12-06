# frozen_string_literal: true

module Xikolo
  module V2::Classifiers
    class Clusters < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'clusters'

        attribute('visible') {
          description 'Whether this cluster is visible to users'
          type :boolean
        }

        attribute('title') {
          description 'The localized cluster title'
          type :string
          reading(&:title)
        }
      end

      collection do
        get 'List all clusters' do
          ::Course::Cluster.all
        end
      end
    end
  end
end
