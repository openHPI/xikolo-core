# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizConsumer, type: :consumer do
  subject(:quiz_event) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.timeeffort = {'enabled' => true}
    Msgr.client.start
  end

  let(:quiz_id) { SecureRandom.uuid }

  let(:payload) { {quiz_id:} }
  let(:publish) { -> { Msgr.publish(payload, to: msgr_route) } }

  describe '#question_changed' do
    let(:msgr_route) { 'xikolo.quiz.question.create' }
    let(:time_effort_job) { instance_double(TimeEffortJob) }

    context 'w/ existing item' do
      let(:item_params) do
        {
          content_id: payload[:quiz_id],
          content_type: 'quiz',
        }
      end
      let!(:item) { create(:'timeeffort_service/item', item_params) }

      it 'creates a TimeEffortJob for the item and schedules a new job' do
        expect(TimeEffortJob).to receive(:create!).once
          .with(item_id: item.id)
          .and_return time_effort_job
        expect(time_effort_job).to receive :schedule
        quiz_event
      end
    end

    context 'w/o existing item' do
      it 'does not raise an error' do
        expect { quiz_event }.not_to raise_error
      end

      it 'does not create a new TimeEffortJob' do
        quiz_event
        expect(TimeEffortJob.count).to eq 0
      end
    end
  end

  describe '#answer_changed' do
    let(:msgr_route) { 'xikolo.quiz.answer.create' }
    let(:time_effort_job) { instance_double(TimeEffortJob) }
    let(:question_id) { SecureRandom.uuid }

    let(:payload) { {question_id:} }

    before do
      Stub.service(:quiz, build(:'quiz:root'))
    end

    context 'w/ existing question' do
      before do
        Stub.request(:quiz, :get, "/questions/#{question_id}")
          .to_return Stub.json({quiz_id:})
      end

      context 'w/ existing item' do
        let(:item_params) do
          {
            content_id: quiz_id,
            content_type: 'quiz',
          }
        end
        let!(:item) { create(:'timeeffort_service/item', item_params) }

        it 'creates a TimeEffortJob for the item and schedules a new job' do
          expect(TimeEffortJob).to receive(:create!).once
            .with(item_id: item.id)
            .and_return time_effort_job
          expect(time_effort_job).to receive :schedule
          quiz_event
        end
      end

      context 'w/o existing item' do
        it 'does not raise an error' do
          expect { quiz_event }.not_to raise_error
        end

        it 'does not create a new TimeEffortJob' do
          expect { quiz_event }.not_to change(TimeEffortJob, :count)
        end
      end
    end

    context 'w/o existing question' do
      before do
        Stub.request(:quiz, :get, "/questions/#{question_id}")
          .to_return Stub.response(status: 404)
      end

      it 'does not raise an error' do
        expect { quiz_event }.not_to raise_error
      end

      it 'does not create a new TimeEffortJob' do
        expect { quiz_event }.not_to change(TimeEffortJob, :count)
      end
    end

    context 'w/ different (unhandled) error' do
      before do
        Stub.request(:quiz, :get, "/questions/#{question_id}")
          .to_return Stub.response(status: 400)
      end

      it 'raises an error' do
        expect { quiz_event }.to raise_error Restify::ClientError
      end
    end
  end
end
