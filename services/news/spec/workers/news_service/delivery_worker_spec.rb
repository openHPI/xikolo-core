# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::DeliveryWorker, type: :worker do
  subject(:worker) { described_class }

  let(:delivery) { create(:'news_service/delivery') }
  let(:user) { {'email' => 'test@example.org'} }

  describe '::call' do
    it 'schedules a background job' do
      expect do
        worker.call(delivery, user)
      end.to change(worker.jobs, :size).by(1)

      expect(worker.jobs.last).to include 'args' => [delivery.id, user]
    end
  end

  describe '#perform' do
    it 'invokes the Delivery::Send operation' do
      expect(NewsService::Delivery::Send).to receive(:call) do |*args|
        aggregate_failures 'operation arguments' do
          expect(args[0]).to eq delivery
          expect(args[1]).to eq user
        end
      end

      Sidekiq::Testing.inline! do
        worker.call(delivery, user)
      end
    end
  end
end
