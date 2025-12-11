# frozen_string_literal: true

require 'quiz_service/xml_importer'
require 'quiz_service/quiz_submission_data_serializer'

module QuizService
  class Engine < ::Rails::Engine
    isolate_namespace QuizService
    config.generators.api_only = true
  end
end
