# frozen_string_literal: true

require 'spec_helper'

describe 'Transpipe API: Show course video', type: :request do
  subject(:request) { get "/bridges/transpipe/videos/#{video_id}", headers: }

  let(:headers) { {'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966'} }
  let(:json) { JSON.parse response.body }
  let(:video_id) { item.content_id }
  let(:item_resource) { build(:'course:item', id: item.id) }
  let(:item) { create(:item, :video, section:) }
  let(:section) { create(:section) }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/items', query: {content_id: video_id})
      .to_return Stub.json([item_resource])
    create(:video_subtitle, video: item.content)
    create(:video_subtitle, video: item.content, lang: 'de')
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  it 'responds with the video details' do
    request
    expect(response).to have_http_status :ok
    expect(json).to include(
      'subtitles',
      'streams',
      'summary' => 'Video for testing.',
      'id' => video_id,
      'course-id' => section.course_id
    )
    expect(json['subtitles'].length).to eq 2
    expect(json['subtitles']).to all include(
      'language',
      'automatic'
    )
    expect(json['streams']).to include(
      'lecturer',
      'pip',
      'slides'
    )
    %w[lecturer pip slides].each do |stream_name|
      expect(json['streams'][stream_name]).to include(
        'hd',
        'sd',
        'hls'
      )
    end
  end

  describe 'authorization / error handling' do
    let(:video_id) { 'video_id' }

    context 'when the video does not exist' do
      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end
  end
end
