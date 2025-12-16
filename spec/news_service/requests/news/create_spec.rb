# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'News: Create', type: :request do
  subject(:request) { service.rel(:news_index).post(announcement_params).value! }

  let(:service) { restify_with_headers(news_service_url).get.value! }

  context 'with invalid data' do
    let(:announcement_params) { {} }

    it 'returns with errors' do
      expect { request }.to raise_error(Restify::ClientError) do |e|
        expect(e.status).to eq :unprocessable_content
        expect(NewsService::News.count).to eq 0
      end
    end
  end

  context 'with valid announcement data' do
    let(:announcement_params) do
      attributes_for(:'news_service/news').merge(title: 'Some title', text: 'A beautiful announcement text')
    end

    it { is_expected.to respond_with :created }

    it 'stores the new announcement' do
      expect { request }.to change(NewsService::News, :count).from(0).to(1)
    end

    it 'also stores the announcement text' do
      request
      translation = NewsService::News.last.translations.find_by(locale: 'en')
      expect(translation.text).to eq 'A beautiful announcement text'
    end

    describe '(json)' do
      it 'returns the created object' do
        expect(request['title']).to eq announcement_params[:title]
      end
    end

    context 'with a translation' do
      let(:german_title) { 'Deutscher Titel' }
      let(:german_text) { 'Deutscher Text' }
      let(:announcement_params) do
        super().merge(
          translations: {
            de: {title: german_title, text: german_text},
          }
        )
      end

      it 'stores exactly one new announcement' do
        expect { request }.to change(NewsService::News, :count).from(0).to(1)
      end

      it 'stores the announcement with English title and text' do
        request
        translation = NewsService::News.last.translations.find_by(locale: 'en')
        expect(translation.title).to eq announcement_params[:title]
        expect(translation.text).to eq announcement_params[:text]
      end

      it 'stores a translation with German title and text' do
        request
        translation = NewsService::News.last.translations.find_by(locale: 'de')
        expect(translation.title).to eq german_title
        expect(translation.text).to eq german_text
      end
    end
  end
end
