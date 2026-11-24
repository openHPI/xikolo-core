# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter do
  subject(:import_quizzes) do
    described_class.import(
      spreadsheet: spreadsheet,
      worksheet: worksheet,
      course_code: course_code
    )
  end

  let(:spreadsheet) { 'Course Spreadsheet' }
  let(:worksheet) { 'Quiz Import' }
  let(:course) { create('course_service/course', skip_account_groups: true) }
  let(:course_code) { course.course_code }
  let(:section) { create(:'course_service/section', course: course, published: true, position: 1) }
  let(:item) { create(:'course_service/item', section:, published: true) }

  let(:rows) { [[], ['test_name', 1, 'survey', 'Please finish this quiz']] }
  let(:quizzes) { [instance_double(QuizImporter::Quiz)] }

  let(:loader) { instance_double(QuizImporter::Loader, load: rows) }

  before do
    allow(QuizImporter::Loader).to receive(:new).and_return(loader)
    allow(CourseService::Course).to receive(:find_by!).and_return(course)
    allow(course).to receive(:sections).and_return(
      CourseService::Section.where(id: section.id)
    )
  end

  it 'loads rows, scans quizzes, resolves course and persists them in order' do
    expect(QuizImporter::Loader).to receive(:new)
      .with(spreadsheet:, worksheet:)
      .ordered
      .and_return(loader)

    expect(loader).to receive(:load)
      .ordered
      .and_return(rows)

    expect { import_quizzes }
      .to change(QuizService::Quiz, :count).by(1)
      .and change(CourseService::Item, :count).by(1)

    quiz = QuizService::Quiz.order(:id).last
    item = CourseService::Item.order(:id).last

    expect(quiz.instructions).to eq('Please finish this quiz')
    expect(quiz.allowed_attempts).to eq(1)

    expect(item.content).to eq(quiz)
    expect(item.title).to eq('test_name')
    expect(item.exercise_type).to eq('survey')
  end

  context 'with a final exam quiz' do
    let(:rows) { [[], ['final_exam', 1, 'final exam', 'Please finish this exam']] }

    it 'persists it as exercise_type exam' do
      expect { import_quizzes }
        .to change(QuizService::Quiz, :count).by(1)
        .and change(CourseService::Item, :count).by(1)

      item = CourseService::Item.order(:id).last

      expect(item.title).to eq('final_exam')
      expect(item.exercise_type).to eq('exam')
    end
  end
end
