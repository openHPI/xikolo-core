# frozen_string_literal: true

require 'spec_helper'

describe Video::ExtractAudioJob, type: :job do
  subject(:enqueue_job) { described_class.perform_later(stream.id) }

  let(:stream) do
    create(:stream,
      id: '72c75162-6aec-4a47-a74f-03a522290279',
      title: 'Test:Title 2',
      sd_url: 'spec/support/files/video-sd.mp4',
      audio_uri:)
  end
  let(:audio_uri) { nil }
  let(:upload_id) { '83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa' }
  let(:file_name) { 'audio.mp3' }

  before do
    xi_config <<~YML
      video:
        audio_extraction: true
    YML
  end

  it 'enqueues a new job' do
    expect { enqueue_job }.to have_enqueued_job(described_class)
      .with(stream.id)
      .on_queue('default')
  end

  describe '#perform' do
    let(:upload_stub) do
      stub_request(:put, %r{https://s3.xikolo.de/xikolo-video/streams/#{stream_uuid}/audio/[0-9a-zA-Z]+/audio.mp3}x)
        .to_return(status: 200, body: '<xml></xml>')
    end
    let(:stream_uuid) { UUID4(stream.id).to_str(format: :base62) }

    before do
      stub_request(:head, "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/audio.mp3")
        .and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'video_streams',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
      stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads/#{stream.id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>uploads/#{upload_id}/#{file_name}</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML
      upload_stub
    end

    around {|example| perform_enqueued_jobs(&example) }

    context 'with no previously generated file' do
      it 'uploads a file to s3 and stores its reference' do
        expect { enqueue_job }.to change { stream.reload.audio_uri }
          .from(nil)
          .to(%r{s3://xikolo-video/streams/#{stream_uuid}/audio/[0-9a-zA-Z]+/audio.mp3}x)
        expect(upload_stub).to have_been_requested
      end
    end

    context 'with a previously generated file' do
      let(:audio_uri) { 's3://xikolo-video/streams/3uAdfU6wveIxOGrQ7qa7mp/audio/1rHXup8qfTbeSupffOYEk5/audio.mp3' }
      let(:delete_stub) do
        stub_request(
          :delete, 'https://s3.xikolo.de/xikolo-video/streams/3uAdfU6wveIxOGrQ7qa7mp/audio/1rHXup8qfTbeSupffOYEk5/audio.mp3'
        ).to_return(status: 200, body: '<xml></xml>')
      end

      before { delete_stub }

      it 'uploads a new file and deletes the old one' do
        expect(stream.reload.audio_uri).not_to be_nil
        expect { enqueue_job }.to change { stream.reload.audio_uri }
          .to(%r{s3://xikolo-video/streams/#{stream_uuid}/audio/[0-9a-zA-Z]+/audio.mp3}x)
        expect(upload_stub).to have_been_requested
        expect(delete_stub).to have_been_requested
      end
    end

    context 'with disabled audio extraction' do
      before do
        xi_config <<~YML
          video:
            audio_extraction: false
        YML
      end

      it 'skips the job' do
        expect { enqueue_job }.not_to change { stream.reload.audio_uri }.from(nil)
        expect(upload_stub).not_to have_been_requested
      end
    end
  end
end
