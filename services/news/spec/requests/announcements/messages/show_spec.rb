# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcement: Message: Show', type: :request do
  subject(:resource) { announcement_resource.rel(:message).get(params).value! }

  let(:service) { Restify.new(:test).get.value! }
  let(:announcement_resource) { service.rel(:announcement).get({id: announcement.id}).value! }
  let(:params) { {} }
  let(:message) { create(:'news_service/message') }
  let(:announcement) { message.announcement }

  it { is_expected.to respond_with :ok }

  describe '(json)' do
    it 'includes all required fields' do
      expect(resource).to have_key('id')
        .and have_key('subject')
        .and have_key('content')
        .and have_key('recipients')
        .and have_key('status')
        .and have_key('creator_id')
        .and have_key('created_at')
        .and have_key('deliveries')
    end

    context 'no deliveries' do
      it 'denotes that no messages have been sent' do
        expect(resource['deliveries']['total']).to be_zero
        expect(resource['deliveries']['success']).to be_zero
      end
    end

    context 'with delivery' do
      before { create(:'news_service/delivery', message:) }

      it 'includes the correct count for deliveries' do
        expect(resource['deliveries']['total']).to eq 1
        expect(resource['deliveries']['success']).to eq 1
      end
    end
  end

  describe 'with different translations' do
    let(:message) { create(:'news_service/message', :with_german_translation) }

    context 'with no language set' do
      it 'responds in English (the default)' do
        expect(resource['subject']).to eq 'English subject'
        expect(resource['content']).to eq 'Oh, you gonna like my news...'
      end
    end

    context 'when requesting :de language' do
      let(:params) { {**super(), language: :de} }

      it 'responds in German' do
        expect(resource['subject']).to eq 'Deutscher Titel'
        expect(resource['content']).to eq 'Das sind interessante News...'
      end
    end

    context 'when requesting non-existing language' do
      let(:params) { {**super(), language: :xx} }

      it 'responds in English (the default)' do
        expect(resource['subject']).to eq 'English subject'
        expect(resource['content']).to eq 'Oh, you gonna like my news...'
      end

      context 'when no English translation exists' do
        let(:message) { create(:'news_service/message', :german_only) }

        it 'responds with German (the only available translation)' do
          expect(resource['subject']).to eq 'Deutscher Titel'
          expect(resource['content']).to eq 'Das sind interessante News...'
        end
      end
    end
  end
end
