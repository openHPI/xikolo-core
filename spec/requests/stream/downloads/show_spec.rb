# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Stream: Downloads: Show', type: :request do
  subject(:show) { get "/streams/#{stream.id}/downloads/#{quality}", headers: }

  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:stream) { create(:stream, hd_download_url: old_hd_url, downloads_expire: expire_at) }
  let(:expire_at) { nil }
  let(:quality) { 'hd' }
  let(:old_hd_url) { 'https://vimeo.com/the_download/hd_old.mp4' }
  let(:new_hd_url) { 'https://vimeo.com/the_download/hd_new.mp4' }
  let(:new_sd_url) { 'https://vimeo.com/the_download/sd_new.mp4' }
  let(:expiration_date) { 12.hours.from_now.iso8601.to_s }
  let(:vimeo_api_stub) do
    stub_request(:get, "https://api.vimeo.com/videos/#{stream.provider_video_id}?fields=download")
      .with(
        headers: {
          'Accept' => 'application/vnd.vimeo.*+json;version=3.4',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer test-token',
        }
      )
      .to_return(status: 200, body: vimeo_response, headers: {})
  end
  let(:vimeo_response) do
    {
      download: [
        {
          quality: 'hd',
          size: '10000',
          link: new_hd_url,
          expires: expiration_date,
        },
        {
          quality: 'sd',
          size: '5000',
          link: new_sd_url,
          expires: expiration_date,
        },
        {
          quality: 'sd',
          size: '2000',
          link: 'https://vimeo.com/the_download/sd_new.mp4',
          expires: expiration_date,
        },
      ],
    }.to_json
  end

  before do
    stub_user_request
    vimeo_api_stub
  end

  describe '(response)' do
    it 'redirects to the specified download URL' do
      show
      expect(response).to redirect_to new_hd_url
    end

    context 'when requesting the download with the short stream UUID' do
      subject(:show) { get "/streams/#{UUID4(stream.id).to_s(format: :base62)}/downloads/#{quality}", headers: }

      it 'redirects to the specified download URL' do
        show
        expect(response).to redirect_to new_hd_url
      end
    end

    context 'for non-expired download links' do
      let(:expire_at) { 10.minutes.from_now }

      it 'does not refresh the download links' do
        show
        expect(vimeo_api_stub).not_to have_been_requested
      end

      it 'matches the stored stream download URL' do
        show
        expect(response).to redirect_to old_hd_url
      end
    end

    context 'for expired download links' do
      let(:expire_at) { 5.minutes.before }

      it 'refreshes the download links in the database' do
        show
        expect(vimeo_api_stub).to have_been_requested

        expect(stream.reload).to match(an_object_having_attributes(
          hd_download_url: 'https://vimeo.com/the_download/hd_new.mp4',
          sd_download_url: 'https://vimeo.com/the_download/sd_new.mp4',
          downloads_expire: expiration_date.to_datetime
        ))
      end

      it 'redirects to the specified download URL' do
        show
        expect(response).to redirect_to new_hd_url
      end

      context 'with failing Vimeo API' do
        let(:vimeo_api_stub) do
          stub_request(:get, "https://api.vimeo.com/videos/#{stream.provider_video_id}?fields=download")
            .to_timeout
        end

        it 'shows the corresponding error message and redirects' do
          show
          expect(response).to redirect_to dashboard_url
          expect(flash[:error].first).to eq 'A valid download link could not be requested from the video provider. Please try again later.'
        end
      end
    end

    context 'with unavailable quality' do
      let(:quality) { 'hd' }
      let(:hd_url) { nil }
      let(:new_hd_url) { nil }

      it 'shows the corresponding error message and redirects' do
        show
        expect(response).to redirect_to dashboard_url
        expect(flash[:error].first).to eq 'This download is unavailable.'
      end
    end

    context 'with unsupported quality' do
      let(:quality) { '4k' }

      it 'shows the corresponding error message and redirects' do
        show
        expect(response).to redirect_to dashboard_url
        expect(flash[:error].first).to eq 'This download is unavailable.'
      end
    end
  end

  context 'for anonymous user' do
    let(:headers) { {} }

    it 'redirects to login page' do
      show
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'when requested by a search engine' do
    let(:headers) do
      {
        'User-Agent' => 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/W.X.Y.Z Safari/537.36',
        'Accept-Language' => 'en-us',
      }
    end

    it 'redirects to download without login wall' do
      show
      expect(response).to redirect_to new_hd_url
    end

    context 'with not expired link' do
      let(:expire_at) { 10.minutes.from_now }

      it 'redirects to download without login wall' do
        show
        expect(response).to redirect_to old_hd_url
      end
    end
  end
end
