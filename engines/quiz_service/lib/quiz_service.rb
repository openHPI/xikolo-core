# frozen_string_literal: true

module QuizService
  class Engine < ::Rails::Engine
    isolate_namespace QuizService
    config.generators.api_only = true
  end
end
