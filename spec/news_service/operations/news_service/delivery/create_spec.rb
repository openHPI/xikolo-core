# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::Delivery::Create, type: :operation do
  subject(:op) { described_class }

  let(:message) { create(:'news_service/message') }
  let(:user) do
    {'id' => '7444735c-9d2b-49db-a031-6d5aa8962fc6'}
  end

  describe '::call' do
    it 'creates a delivery record' do
      expect { op.call(message, user) }.to change(NewsService::Delivery, :count).by(1)

      NewsService::Delivery.first.tap do |delivery|
        expect(delivery.message).to eq message
        expect(delivery.user_id).to eq user['id']
      end
    end

    it 'invokes the delivery job' do
      expect { op.call(message, user) }
        .to have_enqueued_job(NewsService::DeliveryJob)
        .with do |delivery_id, user_arg|
          expect(delivery_id).to eq NewsService::Delivery.first.id
          expect(user_arg).to eq user
        end
    end
  end
end
