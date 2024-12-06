# frozen_string_literal: true

class CourseProviderWorker
  include Sidekiq::Job

  def perform(name, type, config, course_id)
    course = Course.find_by(id: course_id)
    return unless course

    "#{type}::Adapter".constantize.new(name, course, config).sync
  end
end
