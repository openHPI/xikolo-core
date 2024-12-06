# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Delivery::Create, type: :operation do
  subject(:op) { described_class }

  let(:message) { create(:message) }
  let(:user) do
    {'id' => '7444735c-9d2b-49db-a031-6d5aa8962fc6'}
  end

  describe '::call' do
    it 'creates a delivery record' do
      expect { op.call(message, user) }.to change(Delivery, :count).by(1)

      Delivery.first.tap do |delivery|
        expect(delivery.message).to eq message
        expect(delivery.user_id).to eq user['id']
      end
    end

    it 'invokes the delivery worker' do
      expect(DeliveryWorker).to receive(:call) do |delivery, user_arg|
        expect(delivery).to eq Delivery.first
        expect(user_arg).to eq user
      end

      op.call(message, user)
    end
  end
end
