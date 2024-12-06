# frozen_string_literal: true

namespace :learning_evaluation do
  desc <<-DOC.gsub(/\s+/, ' ')
    Compare old and new implementation of learning evaluation for a given enrollment
  DOC
  task :compare, [:enrollment] => :environment do |_task, args|
    enrollment = Enrollment.where(id: args[:enrollment])

    old = LearningEvaluation::Dynamic.new.call(enrollment).first
    new = LearningEvaluation::Persisted.new.call(enrollment).first

    puts 'OLD'
    pp old.decorate.base.slice(:visits, :points, :certificates, :completed)

    puts 'NEW'
    pp new.decorate.base.slice(:visits, :points, :certificates, :completed)
  end
end
