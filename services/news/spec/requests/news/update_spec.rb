# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcements: Update', type: :request do
  subject(:request) { service.rel(:news).patch(update_params, id: announcement.id).value! }

  let(:service) { Restify.new(:test).get.value! }

  let!(:announcement) { create(:news) }
  let(:announcement_id) { announcement.id }
  let(:new_announcement_title) { 'The updated title' }
  let(:new_announcement_text) { 'The updated text' }

  context 'with invalid data' do
    let(:update_params) { {author_id: nil} }

    it 'returns with errors' do
      expect { request }.to raise_error(Restify::ClientError) do |e|
        expect(e.status).to eq :unprocessable_content
      end
    end
  end

  context 'with valid announcement data' do
    let(:update_params) { {title: new_announcement_title, text: new_announcement_text} }

    it { is_expected.to respond_with :ok }

    it 'updates the announcement title' do
      expect { request }.to change {
        News.find(announcement_id).translations.find_by(locale: 'en').title
      }.to(new_announcement_title)
    end

    it 'updates the announcement text' do
      expect { request }.to change {
        News.find(announcement_id).translations.find_by(locale: 'en').text
      }.to(new_announcement_text)
    end

    context 'with a translation' do
      let(:new_german_title) { 'Deutscher Titel' }
      let(:new_german_text) { 'Deutscher Text' }
      let(:update_params) do
        super().merge(
          translations: {
            de: {title: new_german_title, text: new_german_text},
          }
        )
      end

      it 'does not create any new announcements' do
        expect { request }.not_to change(News, :count)
      end

      it 'updates the announcement with the new English title' do
        expect { request }.to change {
          News.find(announcement_id).translations.find_by(locale: 'en').title
        }.to(new_announcement_title)
      end

      it 'updates the translation with the new German title' do
        expect { request }.to change {
          News.find(announcement_id).translations.find_by(locale: 'de')&.title
        }.to(new_german_title)
      end

      it 'updates the announcement with the new English text' do
        expect { request }.to change {
          News.find(announcement_id).translations.find_by(locale: 'en').text
        }.to(new_announcement_text)
      end

      it 'updates the translation with the new German text' do
        expect { request }.to change {
          News.find(announcement_id).translations.find_by(locale: 'de')&.text
        }.to(new_german_text)
      end
    end
  end
end
