# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: update', type: :request do
  subject(:request) do
    api.rel(:channel).patch({name: 'New Name'}, params: {id: identifier}).value!
  end

  let(:api) { Restify.new(:test).get.value }
  let(:channel) { create(:'course_service/channel') }

  context 'identified by ID' do
    let(:identifier) { channel.id }

    it 'responds with an empty body' do
      expect(request).to respond_with :no_content
    end

    it 'updates the channel' do
      expect { request }.to change { channel.reload.name }.to 'New Name'
    end
  end

  context 'identified by code' do
    let(:identifier) { channel.code }

    it 'responds with an empty body' do
      expect(request).to respond_with :no_content
    end

    it 'updates the channel' do
      expect { request }.to change { channel.reload.name }.to 'New Name'
    end
  end
end
