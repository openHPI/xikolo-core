# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'News Email: Create (Send)', type: :request do
  subject(:request) { news_resource.rel(:email).post(payload).value! }

  let(:service) { Restify.new(:test).get.value! }
  let(:news_resource) { service.rel(:news).get({id: announcement.id}).value! }

  let(:announcement) { create(:news) }

  let(:payload) { {} }

  it { is_expected.to respond_with :created }

  it 'stores a record of sending this email' do
    expect do
      request
    end.to change { announcement.emails.count }.from(0).to(1)
  end

  it 'triggers an email to be sent' do
    expect(Msgr).to receive(:publish).with(anything, to: 'xikolo.news.announcement.create')
    request
  end

  context 'for a global announcement' do
    let(:announcement) { create(:news, :global) }

    it 'publishes the correct event payload' do
      expect(Msgr).to receive(:publish) do |*args|
        expect(args[0]).to include course_id: nil
        expect(args[1]).to eq(to: 'xikolo.news.announcement.create')
      end
      request
    end
  end

  context 'for a group-restricted global announcement' do
    let(:announcement) { create(:news, :global, audience: 'xikolo.affiliated') }

    it 'includes the group name in the event payload' do
      expect(Msgr).to receive(:publish) do |*args|
        expect(args[0]).to include course_id: nil, group: 'xikolo.affiliated'
        expect(args[1]).to eq(to: 'xikolo.news.announcement.create')
      end
      request
    end
  end

  context 'with explicit receiver for test email' do
    let(:receiver_id) { SecureRandom.uuid }
    let(:payload) { super().merge test_receiver: receiver_id }

    it { is_expected.to respond_with :created }

    it 'forwards the receiver ID' do
      expect(Msgr).to receive(:publish) do |*args|
        expect(args[0]).to include(receiver_id:)
        expect(args[1]).to eq(to: 'xikolo.news.announcement.create')
      end
      request
    end
  end
end
