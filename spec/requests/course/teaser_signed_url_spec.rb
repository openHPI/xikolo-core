# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Teaser: Signed URL', type: :request do
  subject(:get_signed_url) { get "/learn/#{course.course_code}/teaser_signed_url" }

  let(:course) { create(:course, course_code: 'example') }
  let(:stream) { create(:stream, :bunny, provider_video_id: 'bunny-teaser') }
  let(:video) { create(:video, pip_stream: stream) }
  let(:user) { create(:'account_service/user') }
  let(:permissions) { %w[course.course.show] }

  before do
    create(:visual, course:, video:)
    sign_in(user:)
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)
    Stub.request(:course, :get, "/courses/#{course.course_code}").to_return Stub.json(
      build(:'course:course', id: course.id, course_code: course.course_code)
    )
  end

  it 'redirects to a signed playlist without requiring enrollment or caching the token' do
    get_signed_url

    expect(response).to have_http_status(:found)
    expect(response.location).to include('/bunny-teaser/playlist.m3u8', 'bcdn_token=', 'expires=')
    expect(response.headers['Cache-Control']).to eq 'no-store'
  end

  it 'keeps the playback URL valid for ten minutes' do
    freeze_time do
      get_signed_url

      expect(response.location).to include("expires=#{10.minutes.from_now.to_i}&")
    end
  end

  context 'without permission to view the course' do
    let(:permissions) { [] }

    it 'denies access' do
      get_signed_url

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to root_url
      expect(flash[:error].first).to eq 'You do not have sufficient permissions for this action.'
    end
  end

  context 'with an unpublished course' do
    let(:course) { create(:course, published: false, course_code: 'example') }

    it 'does not expose the teaser' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end

  context 'without a teaser video' do
    let(:video) { nil }

    it 'is not found' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end

  context 'with a Vimeo teaser' do
    let(:stream) { create(:stream, :vimeo) }

    it 'is not found' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end

  context 'with an incomplete Bunny upload' do
    before { stream.update!(upload_state: :uploading) }

    it 'is not found' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end
end
