# frozen_string_literal: true

RSpec.shared_context 'course_service API controller', shared_context: :metadata do
  routes { CourseService::Engine.routes }
end
