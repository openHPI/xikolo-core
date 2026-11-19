# frozen_string_literal: true

require 'spec_helper'

describe '#update_search_index', type: :model do
  context 'when creating a new course' do
    it 'runs the worker for updating the search index' do
      expect { create(:'course_service/course') }.to have_enqueued_job(CourseService::UpdateCourseSearchIndexJob).exactly(:once)
      expect { create(:'course_service/course') }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(2)
    end
  end

  context 'when updating a course' do
    let!(:course) { create(:'course_service/course', :with_teachers) }

    [
      {title: 'An amazing course title'},
      {description: 'An amazing course description'},
      {course_code: 'amazing-course'},
      {abstract: 'Lorem Ipsum'},
      {alternative_teacher_text: 'Jedi'},
      {teacher_ids: []},
      {classifiers: []},
    ].each do |attributes|
      it 'runs the worker for updating the search index' do
        expect { course.update!(attributes) }.to have_enqueued_job(CourseService::UpdateCourseSearchIndexJob).exactly(:once)
        expect { course.update!(attributes) }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(3)
      end
    end
  end
end
