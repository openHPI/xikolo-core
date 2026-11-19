# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::SearchCourseUpdateJob, type: :job do
  subject(:perform_job) { described_class.new.perform(payload) }

  let(:course_id) { generate(:course_id) }
  let(:payload)   { {'id' => course_id, 'lang' => 'de'} }

  let!(:questions) do
    create_list(:'pinboard_service/question', 2, course_id: course_id)
  end

  let!(:course_stub) do
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({id: course_id, course_code: 'code2019', lang: 'en'})
  end

  before do
    create_list(:'pinboard_service/answer', 2, question: questions.first)

    # Ensure search documents are built (english)
    perform_enqueued_jobs(only: PinboardService::UpdateQuestionSearchTextJob)
  end

  describe '#perform' do
    it 'schedules updates for all questions' do
      # Ensure all course search documents are english
      expect(
        PinboardService::Question.where(course_id: course_id).pluck(:language).uniq
      ).to eq ['en']

      # Return new language for course
      remove_request_stub(course_stub)

      Stub.request(:course, :get, "/courses/#{course_id}")
        .to_return Stub.json({id: course_id, course_code: 'code2019', lang: 'de'})

      expect do
        perform_job
      end.to have_enqueued_job(
        PinboardService::UpdateQuestionSearchTextJob
      ).twice

      # Search index is rebuilt
      perform_enqueued_jobs(only: PinboardService::UpdateQuestionSearchTextJob)

      # Ensure all course documents are german now
      expect(
        PinboardService::Question.where(course_id: course_id).pluck(:language).uniq
      ).to eq ['de']
    end
  end
end
