# frozen_string_literal: true

module Xikolo
  module Entities
    class Classifier < Grape::Entity
      expose :id
      expose :title
      expose :cluster_id
      expose :translations

      # @deprecated
      expose def description
        nil
      end

      # @deprecated
      expose def name
        object.title
      end

      # @deprecated
      expose def cluster
        object.cluster_id
      end
    end
  end
end
