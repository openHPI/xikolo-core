# frozen_string_literal: true

RSpec.shared_context 'quiz_service API controller', shared_context: :metadata do
  routes { QuizService::Engine.routes }
end
