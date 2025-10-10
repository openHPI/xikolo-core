# frozen_string_literal: true

module CourseService
  class Engine < ::Rails::Engine
    isolate_namespace CourseService
    config.generators.api_only = true
  end
end
