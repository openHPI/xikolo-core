# frozen_string_literal: true

module Steps
  module Progress
    module Places
      When 'I am on the progress page' do
        context.with :course do |course|
          visit "/courses/#{course['course_code']}/progress"
        end
      end

      When 'I visit the syllabus page' do
        context.with :course do |course|
          visit "/courses/#{course['course_code']}/overview"
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Progress::Places }
