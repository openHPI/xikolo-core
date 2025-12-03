# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::Delivery::Send, type: :operation do
  subject(:op) { described_class }

  let(:delivery) { create(:'news_service/delivery') }

  let(:user) do
    {'email' => 'test@example.org'}
  end

  before do
    allow(NewsService::AnnouncementMailer).to receive(:call)
  end

  describe '::call' do
    it 'invokes announcement mailer' do
      expect(NewsService::AnnouncementMailer).to \
        receive(:call).with(delivery.message, user)

      op.call(delivery, user)
    end

    it 'sets sent_at' do
      expect { op.call(delivery, user) }.to \
        change { delivery.reload.sent_at }.from(nil)
    end

    it 'only sends mails once' do
      expect(NewsService::AnnouncementMailer).to receive(:call).once

      2.times { op.call(delivery, user) }
    end

    it 'acquires a record lock to avoid sending twice concurrently', dbc: :truncation do
      expect(NewsService::AnnouncementMailer).not_to receive(:call)

      id = delivery.id
      event = Concurrent::Event.new

      t = Thread.new do
        d = NewsService::Delivery.find(id)
        d.with_lock do
          event.set
          sleep 0.1
          d.update! sent_at: Time.now.utc
        end
      end

      event.wait(1)
      op.call(delivery, user)

      t.join
    end
  end
end
