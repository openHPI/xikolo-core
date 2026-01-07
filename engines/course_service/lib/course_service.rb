# frozen_string_literal: true

require 'scientist'
require 'course_service/experiment'

module CourseService
  class Engine < ::Rails::Engine
    isolate_namespace CourseService
    config.generators.api_only = true
  end
end
