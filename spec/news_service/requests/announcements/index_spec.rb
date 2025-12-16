# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcements: Index', type: :request do
  subject(:resource) { service.rel(:announcements).get(params).value! }

  let(:service) { restify_with_headers(news_service_url).get.value! }
  let(:params) { {} }
  let(:announcement) { create(:'news_service/announcement', :with_message) }

  before do
    # Create an announcement
    announcement
  end

  it { is_expected.to respond_with :ok }

  it 'returns all announcements' do
    expect(resource.pluck('id')).to contain_exactly(announcement.id)
  end

  describe '(json)' do
    it 'includes all required fields' do
      expect(resource).to all have_key('id')
        .and have_key('author_id')
        .and have_key('title')
        .and have_key('created_at')
        .and have_key('publication_channels')
    end
  end

  describe 'with different translations' do
    subject(:representation) { resource.first }

    let(:announcement) { create(:'news_service/announcement', :with_german_translation, :with_message) }

    context 'with no language set' do
      it 'responds in English (the default)' do
        expect(representation['title']).to eq 'English subject'
      end
    end

    context 'when requesting :de language' do
      let(:params) { {**super(), language: :de} }

      it 'responds in German' do
        expect(representation['title']).to eq 'Deutscher Titel'
      end
    end

    context 'when requesting non-existing language' do
      let(:params) { {**super(), language: :xx} }

      it 'responds in English (the default)' do
        expect(representation['title']).to eq 'English subject'
      end

      context 'when no English translation exists' do
        let(:announcement) { create(:'news_service/announcement', :german_only, :with_message) }

        it 'responds with German (the only available translation)' do
          expect(representation['title']).to eq 'Deutscher Titel'
        end
      end
    end
  end
end
