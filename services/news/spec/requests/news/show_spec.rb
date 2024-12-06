# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'News: Show', type: :request do
  subject(:request) { service.rel(:news).get(params).value! }

  let(:service) { Restify.new(:test).get.value! }

  let(:params) { {id: announcement_id} }

  let(:announcement_id) { announcement.id }
  let!(:announcement) { create(:news) }

  it { is_expected.to respond_with :ok }

  describe '(json)' do
    it { is_expected.to have_rel :self }
    it { is_expected.to have_rel :email }
    it { is_expected.to have_rel :user_visit }
  end

  describe '(msgpack)' do
    let(:service) do
      Restify.new(
        :test,
        headers: {'Accept' => 'application/msgpack, application/json'}
      ).get.value!
    end

    it 'returns a Msgpack-encoded response' do
      expect(request.response.content_type).to eq 'application/msgpack'
    end

    it { is_expected.to have_rel :self }
    it { is_expected.to have_rel :email }
    it { is_expected.to have_rel :user_visit }
  end

  describe 'with different translations' do
    let!(:announcement) { create(:news, :with_german_translation) }

    context 'with no language set' do
      it 'responds in English (the default)' do
        expect(request['title']).to eq 'Some title'
        expect(request['text']).to eq 'A beautiful announcement text'
      end

      context 'with embed=translations' do
        let(:params) { super().merge(embed: 'translations') }

        it 'embeds the German translation (the only other one)' do
          expect(request['translations']).to eq(
            'de' => {
              'title' => 'Deutscher Titel',
              'text' => 'Deutscher Text',
            }
          )
        end
      end
    end

    context 'when requesting :de language' do
      let(:params) { super().merge(language: :de) }

      it 'responds in German' do
        expect(request['title']).to eq 'Deutscher Titel'
        expect(request['text']).to eq 'Deutscher Text'
      end

      context 'with embed=translations' do
        let(:params) { super().merge(embed: 'translations') }

        it 'embeds the English translation (the only other one)' do
          expect(request['translations']).to eq(
            'en' => {
              'title' => 'Some title',
              'text' => 'A beautiful announcement text',
            }
          )
        end
      end
    end

    context 'when requesting non-existing language' do
      let(:params) { super().merge(language: :xx) }

      it 'responds in English (the default)' do
        expect(request['title']).to eq 'Some title'
        expect(request['text']).to eq 'A beautiful announcement text'
      end

      context 'when no English translation exists' do
        before do
          announcement.translations.where(locale: 'en').delete_all
        end

        it 'responds with German (the only available translation)' do
          expect(request['title']).to eq 'Deutscher Titel'
          expect(request['text']).to eq 'Deutscher Text'
        end
      end
    end
  end
end
