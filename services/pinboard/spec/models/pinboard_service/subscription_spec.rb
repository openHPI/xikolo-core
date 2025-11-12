# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Subscription, type: :model do
  context '(event publication)' do
    subject(:subscription) do
      build(:'pinboard_service/subscription', question_id: question.id)
    end

    # Always create question before the spec to avoid leaking
    # `Msgr.publish` calls from creating the question into
    # the expectations for subscriptions.
    let!(:question) { create(:'pinboard_service/question') }

    describe '#create' do
      it 'publishes an event to create route' do
        expect(Msgr).to receive(:publish).with(
          kind_of(Hash),
          to: 'xikolo.pinboard.subscription.create'
        )

        subscription.save
      end
    end

    describe '#destroy' do
      it 'publishes an event to destroy route' do
        subscription.save

        expect(Msgr).to receive(:publish).with(
          hash_including(
            'user_id' => subscription.user_id,
            'question_id' => subscription.question_id
          ),
          to: 'xikolo.pinboard.subscription.destroy'
        )

        subscription.destroy
      end
    end
  end
end
