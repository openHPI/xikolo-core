# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: update', type: :request do
  subject(:request) do
    api.rel(:channel).patch({title_translations: {'de' => 'Neuer Name', 'en' => 'New Name'}}, params: {id: identifier}).value!
  end

  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let(:channel) { create(:'course_service/channel') }

  context 'identified by ID' do
    let(:identifier) { channel.id }

    it 'responds with an empty body' do
      expect(request).to respond_with :no_content
    end

    it 'updates the channel' do
      expect { request }.to change { channel.reload.title_translations['en'] }.to 'New Name'
    end
  end

  context 'identified by code' do
    let(:identifier) { channel.code }

    it 'responds with an empty body' do
      expect(request).to respond_with :no_content
    end

    it 'updates the channel' do
      expect { request }.to change { channel.reload.title_translations['en'] }.to 'New Name'
    end
  end
end
