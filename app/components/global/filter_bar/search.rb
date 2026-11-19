# frozen_string_literal: true

module Global
  module FilterBar
    class Search < ApplicationComponent
      def initialize(name, search_param, label: nil)
        @name = name
        @search_param = search_param
        @label = label
      end
    end
  end
end
