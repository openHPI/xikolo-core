# frozen_string_literal: true

require 'spec_helper'

describe CreateNotificationsWorker, type: :worker do
  subject(:work) { worker.perform event_id, subscriber_ids }

  let(:worker) { CreateNotificationsWorker.new }

  let(:event) { create(:'notification_service/event', key: 'pinboard.discussion.new') }

  let(:event_id) { event.id }
  let(:subscriber_ids) { [] }

  before do
    allow(worker).to receive(:notify_all)
  end

  it 'sends the correct email' do
    work
    expect(worker).to have_received(:notify_all).with([], event.mail_template, anything)
  end

  context 'with subscribers' do
    let(:subscriber_ids) do
      [SecureRandom.uuid, SecureRandom.uuid]
    end
    let(:author_id) { subscriber_ids.first }

    before do
      event.payload = event.payload.merge('user_id' => author_id)
      event.save
    end

    it 'creates platform notifications for all subscribers' do
      expect { work }.to change { event.notifications.count }.by(subscriber_ids.size)
    end

    it 'sends emails to all subscribers but the author' do
      work
      expect(worker).to have_received(:notify_all).with([subscriber_ids.second], event.mail_template, anything)
    end
  end
end
