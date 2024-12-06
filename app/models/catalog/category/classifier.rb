# frozen_string_literal: true

module Catalog
  module Category
    ##
    # An automatic course category that loads courses tagged with a given
    # classifier. All publicly visible courses, regardless of start date and
    # duration, may show up, oldest (by start date) first.
    #
    # By default, 4 courses will be loaded from the classifier. This number can
    # be overwritten.
    #
    class Classifier
      def initialize(cluster_id, classifier_title, max: 4)
        @cluster_id = cluster_id
        @classifier_title = classifier_title
        @max = max
      end

      def title
        classifier.title
      end

      def url
        nil
      end

      def courses
        @courses ||= ::Catalog::Course.released
          .by_classifier(@cluster_id, @classifier_title)
          .for_guests
          .order_chronologically
          .take(@max)
      end

      private

      def classifier
        @classifier ||= ::Course::Classifier
          .where(cluster_id: @cluster_id)
          .find_by!(title: @classifier_title)
      end
    end
  end
end
