# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::Message::Create, type: :operation do
  subject(:op) { described_class }

  let(:recipients) { [build(:'recipient:user'), build(:'recipient:group')] }
  let(:consents) { %w[treatment.marketing treatment.other] }
  let(:announcement) { create(:'news_service/announcement', recipients:) }

  it 'creates message for announcement' do
    expect { op.call(announcement, consents:) }.to change(NewsService::Message, :count).by(1)

    NewsService::Message.first.tap do |message|
      expect(message.announcement_id).to eq announcement.id
      expect(message.recipients).to eq recipients
      expect(message.consents).to eq consents
      expect(message.creator_id).to eq announcement.author_id
    end
  end

  it 'invokes the message worker' do
    expect { op.call(announcement) }
      .to have_enqueued_job(NewsService::MessageJob)
      .with do |message_id|
        expect(message_id).to eq NewsService::Message.first.id
      end
  end

  context 'with a minimal announcement' do
    let(:announcement) { create(:'news_service/announcement') }

    it 'can override the list of recipients' do
      op.call(announcement, recipients:)

      expect(NewsService::Message.count).to eq 1

      NewsService::Message.first.tap do |message|
        expect(message.announcement_id).to eq announcement.id
        expect(message.recipients).to eq recipients
      end
    end

    it 'can explicitly set a creator' do
      creator = generate(:user_id)
      op.call(announcement, recipients:, creator_id: creator)

      expect(NewsService::Message.count).to eq 1

      NewsService::Message.first.tap do |message|
        expect(message.announcement_id).to eq announcement.id
        expect(message.recipients).to eq recipients
        expect(message.creator_id).to eq creator
      end
    end
  end
end
