# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: delete', type: :request do
  subject(:request) do
    api.rel(:channel).delete({id: identifier}).value!
  end

  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let!(:channel) { create(:'course_service/channel') }

  context 'identified by ID' do
    let(:identifier) { channel.id }

    it 'responds with an empty body' do
      expect(request).to respond_with :no_content
    end

    it 'removes the channel' do
      expect { request }.to change(CourseService::Channel, :count).from(1).to(0)
    end
  end

  context 'identified by code' do
    let(:identifier) { channel.code }

    it 'responds with an empty body' do
      expect(request).to respond_with :no_content
    end

    it 'removes the channel' do
      expect { request }.to change(CourseService::Channel, :count).from(1).to(0)
    end
  end
end
