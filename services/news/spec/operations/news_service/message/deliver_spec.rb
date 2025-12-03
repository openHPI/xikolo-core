# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::Message::Deliver, type: :operation do
  subject(:op) { described_class }

  let(:message) { create(:'news_service/message') }

  describe '::call' do
    context 'with a list of recipients' do
      # recipient can be any object responding to #each
      let(:recipient) { [user1, user2] }

      let(:user1) { instance_double(Hash) }
      let(:user2) { instance_double(Hash) }

      it 'invokes Delivery::Create for the user' do
        expect(NewsService::Delivery::Create).to receive(:call).once.with(message, user1)
        expect(NewsService::Delivery::Create).to receive(:call).once.with(message, user2)

        op.call(message, recipient)
      end
    end
  end
end
