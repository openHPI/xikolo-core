# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::PinboardSearchCourseConsumer, type: :consumer do
  let(:course_id) { generate(:course_id) }

  let!(:questions) do
    create_list(:'pinboard_service/question', 2, course_id:)
  end

  let!(:course_stub) do
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({id: course_id, course_code: 'code2019', lang: 'en'})
  end

  before do
    create_list(:'pinboard_service/answer', 2, question: questions.first)

    # Ensure search documents are build
    PinboardService::UpdateQuestionSearchTextWorker.drain
  end

  describe '#update' do
    it 'schedules updates for all questions' do
      # Ensure all course search documents are english
      expect(PinboardService::Question.where(course_id:).pluck(:language).uniq).to eq ['en']

      # Return new language for course
      remove_request_stub(course_stub)

      Stub.request(:course, :get, "/courses/#{course_id}")
        .to_return Stub.json({id: course_id, course_code: 'code2019', lang: 'de'})

      Msgr.client.stop delete: true
      Msgr.client.start

      # Course language is changed to german
      Msgr.publish({id: course_id, lang: 'de'}, to: 'xikolo.course.course.update')

      expect do
        Msgr::TestPool.run count: 1
        # NOTE: It is not clear why the test environment executes the queued messages
        # twice. The issues it ignored.
      end.to change(PinboardService::UpdateQuestionSearchTextWorker.jobs, :size).by(2)

      # Search index is rebuild
      PinboardService::UpdateQuestionSearchTextWorker.drain

      # Ensure all course documents are german now
      expect(PinboardService::Question.where(course_id:).pluck(:language).uniq).to eq ['de']
    end
  end
end
