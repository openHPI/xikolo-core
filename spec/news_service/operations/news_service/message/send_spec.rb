# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::Message::Send, type: :operation do
  subject(:op) { described_class }

  let(:recipients) { ['user:john', 'group:active'] }
  let(:message) { create(:'news_service/message', recipients:) }

  describe '::call' do
    it 'invokes a recipient job for each recipient' do
      expect { op.call(message) }
        .to have_enqueued_job(NewsService::RecipientJob).with(message.id, recipients[0])
        .and have_enqueued_job(NewsService::RecipientJob).with(message.id, recipients[1])
    end
  end
end
