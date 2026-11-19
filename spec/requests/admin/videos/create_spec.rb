# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Videos: Create', type: :request do
  subject(:create_video) { post '/videos', params: }

  let(:user) { create(:'account_service/user', :admin) }
  let(:create_video_blob) do
    ActiveStorage::Blob.create_after_unfurling!(
      io: StringIO.new('video data'),
      filename: 'video.mp4',
      content_type: 'video/mp4'
    )
  end
  let(:params) do
    {
      video_stream: {
        title: 'My uploaded video',
        video: create_video_blob.signed_id,
      },
    }
  end

  before do
    sign_in(user:)
  end

  # The stream is persisted before it is created on Bunny, so the controller
  # never talks to Bunny directly. Creation + upload happen in the enqueued job.
  it 'creates a pending Bunny stream without a provider video id' do
    expect { create_video }.to change(Video::Stream, :count).by(1)

    stream = Video::Stream.last
    expect(stream.provider.provider_type).to eq 'bunny'
    expect(stream.provider_video_id).to be_nil
    expect(stream.upload_state).to eq 'waiting'
  end

  it 'uses the uploaded filename when no title is given' do
    params[:video_stream][:title] = nil
    create_video

    expect(Video::Stream.last.title).to eq 'video.mp4'
  end

  it 'attaches the video' do
    create_video
    expect(Video::Stream.last.video).to be_attached
  end

  it 'enqueues the upload job for the created stream' do
    create_video

    job = enqueued_jobs.find {|j| j[:job] == UploadStreamToBunnyJob }
    expect(job).to be_present
    expect(job[:args]).to eq([Video::Stream.last.id])
  end

  it 'redirects to the videos index' do
    create_video
    expect(response).to redirect_to(videos_path)
  end

  context 'without an uploaded video' do
    let(:params) do
      {
        video_stream: {
          title: 'My uploaded video',
        },
      }
    end

    it 'does not create a stream' do
      expect { create_video }.not_to change(Video::Stream, :count)
    end

    it 're-renders the form with an error' do
      create_video
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template :new
    end
  end

  context 'without permissions' do
    let(:user) { create(:'account_service/user') }

    it 'redirects to the start page' do
      create_video
      expect(response).to redirect_to root_url
    end
  end

  describe 'new' do
    subject(:get_new) { get '/videos/new' }

    it 'renders the standalone upload form' do
      get_new
      expect(response).to have_http_status :ok
      expect(response.body).to include I18n.t(:'admin.videos.upload.headline')
      expect(response.body).to include 'video_stream[title]'
      expect(response.body).to include 'video_stream[video]'
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

      it 'redirects to the start page' do
        get_new
        expect(response).to redirect_to root_url
      end
    end
  end
end
