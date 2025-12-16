# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcement: Show', type: :request do
  subject(:resource) { service.rel(:announcement).get(params).value! }

  let(:service) { restify_with_headers(news_service_url).get.value! }
  let(:params) { {id: announcement.id} }
  let(:announcement) { create(:'news_service/announcement', :with_message) }

  it { is_expected.to respond_with :ok }

  it 'returns the correct announcement' do
    expect(resource['id']).to eq announcement.id
  end

  describe '(json)' do
    it 'includes all required fields' do
      expect(resource).to have_key('id')
        .and have_key('author_id')
        .and have_key('title')
        .and have_key('created_at')
        .and have_key('publication_channels')
    end
  end

  describe 'with different translations' do
    let(:announcement) { create(:'news_service/announcement', :with_german_translation, :with_message) }

    context 'with no language set' do
      it 'responds in English (the default)' do
        expect(resource['title']).to eq 'English subject'
      end
    end

    context 'when requesting :de language' do
      let(:params) { {**super(), language: :de} }

      it 'responds in German' do
        expect(resource['title']).to eq 'Deutscher Titel'
      end
    end

    context 'when requesting non-existing language' do
      let(:params) { {**super(), language: :xx} }

      it 'responds in English (the default)' do
        expect(resource['title']).to eq 'English subject'
      end

      context 'when no English translation exists' do
        let(:announcement) { create(:'news_service/announcement', :german_only, :with_message) }

        it 'responds with German (the only available translation)' do
          expect(resource['title']).to eq 'Deutscher Titel'
        end
      end
    end
  end
end
