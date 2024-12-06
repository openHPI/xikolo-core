# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::CourseItems::Videos do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let(:permissions) { ['course.content.access.available'] }

  let(:item) { create(:item, content: video) }
  let(:video) do
    create(:video, :with_attachments, :with_subtitles,
      pip_stream: create(:stream, :with_downloads,
        duration: 125,
        poster: 'http://pip.stream.url/poster.jpg'),
      description: 'My API video.')
  end
  let(:json) { JSON.parse(response.body) }

  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'HTTP_AUTHORIZATION' => "Legacy-Token #{stub_session_id}",
    }
  end

  let!(:audio_url_stub) do
    stub_request(:head, 'https://s3.xikolo.de/audio.url/')
      .with(
        headers: {
          'Expect' => '',
          'Transfer-Encoding' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus',
        }
      ).to_return(status: 200, body: '', headers: {'CONTENT_LENGTH' => '100'})
  end

  before do
    api_stub_user
    api_stub_user permissions:, context_id: item.section.course.context_id

    audio_url_stub
    stub_request(:head, 'https://s3.xikolo.de/slides.url/')
      .with(
        headers: {
          'Expect' => '',
          'Transfer-Encoding' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus',
        }
      ).to_return(status: 200, body: '', headers: {'CONTENT_LENGTH' => '200'})
    stub_request(:head, 'https://s3.xikolo.de/transcript.stream.url/')
      .with(
        headers: {
          'Expect' => '',
          'Transfer-Encoding' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus',
        }
      ).to_return(status: 200, body: '', headers: {'CONTENT_LENGTH' => '300'})
  end

  describe 'GET videos/:id' do
    subject(:response) { get "/v2/videos/#{video.id}", nil, env_hash }

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    context 'without an enrollment' do
      let(:permissions) { [] }

      it 'responds with 403 Forbidden' do
        expect(response.status).to eq 403
      end
    end

    context 'as an administrator' do
      let(:permissions) { ['course.content.access'] }

      it 'responds with 200 Ok' do
        expect(response.status).to eq 200
      end
    end

    context 'without a corresponding item' do
      let(:item) { create(:item) }

      it 'responds with 404 Not Found' do
        expect(response.status).to eq 404
      end
    end

    it 'contains all the attributes' do
      expect(json['data']['attributes']).to match hash_including(
        'summary' => 'My API video.',
        'duration' => 125,
        'slides_url' => 'https://s3.xikolo.de/slides.url/',
        'audio_url' => 'https://s3.xikolo.de/audio.url/',
        'transcript_url' => 'https://s3.xikolo.de/transcript.stream.url/',
        'thumbnail_url' => 'http://pip.stream.url/poster.jpg',
        'subtitles' => [{'language' => 'en', 'created_by_machine' => false,
                        'vtt_url' => "https://xikolo.de/subtitles/#{video.subtitles[0].id}"},
                        {'language' => 'de', 'created_by_machine' => false,
                        'vtt_url' => "https://xikolo.de/subtitles/#{video.subtitles[1].id}"}]
      )
    end

    it 'contains a link to the related subtitle tracks' do
      expect(json['data']['relationships']).to eq(
        'subtitle-tracks' => {
          'links' => {
            'related' => "/api/v2/subtitle-tracks?filter%5Bvideo%5D=#{video.id}",
          },
        }
      )
    end

    it 'contains the link to itself' do
      expect(json['data']['links']['self']).to eq "/api/v2/videos/#{video.id}"
    end

    context 'with S3 files being loaded successfully' do
      it 'includes the correct file sizes' do
        expect(json['data']['attributes']).to match hash_including(
          'slides_size' => 200,
          'audio_size' => 100,
          'transcript_size' => 300
        )
      end
    end

    context 'with an S3 file which cannot be loaded' do
      let(:audio_url_stub) do
        stub_request(:head, 'https://s3.xikolo.de/audio.url/')
          .with(
          headers: {
            'Expect' => '',
          'Transfer-Encoding' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus',
          }
        )
          .to_return(status: 404, body: '', headers: {})
      end

      it 'includes the correct file sizes' do
        expect(json['data']['attributes']).to match hash_including(
          'slides_url' => 'https://s3.xikolo.de/slides.url/',
          'slides_size' => 200,
          'audio_url' => nil,
          'audio_size' => 0,
          'transcript_url' => 'https://s3.xikolo.de/transcript.stream.url/',
          'transcript_size' => 300
        )
      end
    end
  end
end
