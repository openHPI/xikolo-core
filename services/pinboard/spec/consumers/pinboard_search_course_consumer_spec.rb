# frozen_string_literal: true

require 'spec_helper'

describe PinboardSearchCourseConsumer, type: :consumer do
  let(:course_id) { generate(:course_id) }

  let!(:questions) do
    create_list(:question, 2, course_id:)
  end

  let!(:course_stub) do
    Stub.service(:course, course_url: '/courses/{id}')

    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({id: course_id, course_code: 'code2019', lang: 'en'})
  end

  before do
    Msgr.client.start

    create_list(:answer, 2, question: questions.first)

    # Ensure search documents are build
    UpdateQuestionSearchTextWorker.drain
  end

  describe '#update' do
    it 'schedules updates for all questions' do
      # Ensure all course search documents are english
      expect(Question.where(course_id:).pluck(:language).uniq).to eq ['en']

      # Return new language for course
      remove_request_stub(course_stub)

      Stub.request(:course, :get, "/courses/#{course_id}")
        .to_return Stub.json({id: course_id, course_code: 'code2019', lang: 'de'})

      # Course language is changed to german
      Msgr.publish({id: course_id, lang: 'de'}, to: 'xikolo.course.course.update')

      expect do
        Msgr::TestPool.run count: 1
      end.to change(UpdateQuestionSearchTextWorker.jobs, :size).by(2)

      # Search index is rebuild
      UpdateQuestionSearchTextWorker.drain

      # Ensure all course documents are german now
      expect(Question.where(course_id:).pluck(:language).uniq).to eq ['de']
    end
  end
end
