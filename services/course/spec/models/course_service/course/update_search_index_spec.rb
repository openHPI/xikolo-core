# frozen_string_literal: true

require 'spec_helper'

describe '#update_search_index', type: :model do
  context 'when creating a new course' do
    it 'runs the worker for updating the search index' do
      expect { create(:'course_service/course') }.to change { CourseService::UpdateCourseSearchIndexWorker.jobs.count }.by(1)
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
        expect { course.update!(attributes) }.to change { CourseService::UpdateCourseSearchIndexWorker.jobs.count }.by(1)
      end
    end
  end
end
