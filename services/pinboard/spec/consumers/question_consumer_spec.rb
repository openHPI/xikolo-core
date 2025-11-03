# frozen_string_literal: true

require 'spec_helper'

describe QuestionConsumer, type: :consumer do
  let(:consumer)    { QuestionConsumer.new }
  let(:question_id) { '0c4963fd-c17e-41ad-ad6b-71df292e6de0' }
  let(:user_id)     { 'd0160b58-5a11-4e1f-b8e3-35467daf6daa' }
  let(:message)     { instance_double(Msgr::Message) }
  let(:payload)     { {question_id:, user_id:, timestamp: Time.zone.now} }

  before do
    create(:'pinboard_service/question', id: question_id)

    consumer.instance_variable_set(:@message, message)
    allow(message).to receive(:ack)
    allow(message).to receive(:payload).and_return(payload)
  end

  describe '#read_question' do
    context 'first time' do
      it 'creates a new Watch' do
        expect { consumer.read_question }.to change(Watch, :count).from(0).to(1)
      end
    end

    context 'second time' do
      let(:watch) { create(:'pinboard_service/watch', user_id:, question_id:, updated_at: 1.year.ago) }

      it 'updates Watch' do
        expect { consumer.read_question }.to change { watch.reload; watch.updated_at }
      end

      context 'given someone else is watching' do
        let(:other_watch) { create(:'pinboard_service/watch', question_id:, updated_at: 1.year.ago) }

        before { watch; other_watch }

        it 'does not update Watch of someone else' do
          expect { consumer.read_question }.not_to change { other_watch.reload; other_watch.updated_at }
        end
      end
    end
  end
end
