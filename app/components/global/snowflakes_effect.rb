# frozen_string_literal: true

module Global
  class SnowflakesEffect < ApplicationComponent
    def initialize(show_on_paths: [])
      @show_on_paths = show_on_paths
    end

    def render?
      @show_on_paths.include?(request.path)
    end
  end
end
