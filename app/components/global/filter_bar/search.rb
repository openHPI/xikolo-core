# frozen_string_literal: true

module Global
  module FilterBar
    class Search < ApplicationComponent
      def initialize(name, search_param)
        @name = name
        @search_param = search_param
      end
    end
  end
end
