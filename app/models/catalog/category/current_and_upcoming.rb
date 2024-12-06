# frozen_string_literal: true

module Catalog
  module Category
    ##
    # An automatic course category that loads courses that are currently
    # running or will start soon, ordered by start date.
    #
    class CurrentAndUpcoming
      def initialize(max: 4)
        @max = max
      end

      def title
        I18n.t(:'home.courses')
      end

      def url
        '/courses'
      end

      def courses
        @courses ||= ::Catalog::Course.released.for_global_list.for_guests.then do |scope|
          [
            scope.current,
            scope.upcoming,
          ].reduce(:or)
        end.order_chronologically.take(@max)
      end
    end
  end
end
