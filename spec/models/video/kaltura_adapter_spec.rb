# frozen_string_literal: true

require 'spec_helper'

describe Video::KalturaAdapter do
  subject(:adapter) { described_class.new(provider) }

  let(:provider) do
    create(:video_provider, :kaltura,
      credentials: {
        'partner_id' => 1_234_567,
        'token_id' => '1_rjbgukyi',
        'token' => 'a819271b6406e02d54b70da54bb906a5',
      })
  end
  let(:widget_session_response) { File.read('./spec/support/files/video/kaltura/widget_session_response.xml') }
  let(:privileged_session_response) { File.read('./spec/support/files/video/kaltura/privileged_session_response.xml') }
  let(:media_entries_response) { File.read('./spec/support/files/video/kaltura/media_entries_response.xml') }
  let(:flavor_asset_1) { File.read('./spec/support/files/video/kaltura/flavor_asset_1.xml') }
  let(:flavor_asset_2) { File.read('./spec/support/files/video/kaltura/flavor_asset_2.xml') }
  let(:flavor_asset_3) { File.read('./spec/support/files/video/kaltura/flavor_asset_3.xml') }
  let(:kaltura_session_token) do
    'djJ8NDU0OTM5M3yzha9MF2eOAOcR5fcyDslZrgHA7eMLWlL0UanuMYAHPi-LC3BCvdoDqz4pariQ6K3loqBvPn6PN6vb7rRXrwNxr5xQkqpV6TY' \
      'lFMDWIbU4vFy9t5hszsOgzNEPiP_9ay-9P6uzCQO5BiwZJO4-w9xrI04-7RVSsV3q4CQ6h6kdom9yXhUvlLwJJkVksZbyJCY='
  end

  before do
    stub_request(:post, 'https://www.kaltura.com/api_v3/service/session/action/startWidgetSession')
      .with(body: hash_including(widgetId: '_1234567'))
      .to_return(status: 200, body: widget_session_response, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})

    stub_request(:post, 'https://www.kaltura.com/api_v3/service/apptoken/action/startSession')
      .with(body: hash_including(
        id: '1_rjbgukyi',
        tokenHash: '875eef384da0ae9c086d0633b76b24ddad0ea7069e3a446e16d7a97c19f97459',
        userId: '',
        ks: 'djJ8NDU0OTM5M3yJfv9ZaoCpKOptEULvxMhsuw1cncoUFSsm587ollEMm1qRW8jzZMh9IHpNe41clgk3DdgLnozMw30A1ytukbcNq9wzDgLxa-GeToPW-etaeQ=='
      )).to_return(status: 200, body: privileged_session_response, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})

    xi_config <<~YML
      kaltura:
        api_url: https://www.kaltura.com
        asset_url: https://cdnapisec.kaltura.com/p
        flavors:
          source: 0
          sd: 487071
          hd: 487091
    YML
  end

  describe '#sync' do
    subject(:sync) { adapter.sync(since: provider.synchronized_at, full: true) }

    let!(:media_list_request) do
      stub_request(:post, 'https://www.kaltura.com/api_v3/service/media/action/list')
        .with(body: hash_including(
          :filter, :pager,
          ks: kaltura_session_token
        )).to_return(status: 200, body: media_entries_response, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})
    end

    before do
      media_list_request

      stub_request(:post, 'https://www.kaltura.com/api_v3/service/flavorasset/action/getFlavorAssetsWithParams')
        .with(body: hash_including(entryId: '1_jrdhwl7x'))
        .to_return(status: 200, body: flavor_asset_1, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})

      stub_request(:post, 'https://www.kaltura.com/api_v3/service/flavorasset/action/getFlavorAssetsWithParams')
        .with(body: hash_including(entryId: '1_onu0bd7k'))
        .to_return(status: 200, body: flavor_asset_2, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})

      stub_request(:post, 'https://www.kaltura.com/api_v3/service/flavorasset/action/getFlavorAssetsWithParams')
        .with(body: hash_including(entryId: '1_vk282t4e'))
        .to_return(status: 200, body: flavor_asset_3, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})
    end

    it 'stores new streams from API' do
      expect { sync }.to change(Video::Stream, :count).from(0).to(3)
      expect(media_list_request).to have_been_requested.once
      expected_sd_sizes = {
        '1_jrdhwl7x': 91_000_549,
        '1_onu0bd7k': 42_127_287,
        '1_vk282t4e': 18_250_180,
      }

      expected_sd_sizes.each do |entry_id, size|
        stream = Video::Stream.find_by(provider_video_id: entry_id)
        expect(stream.sd_url).to eq "https://cdnapisec.kaltura.com/p/1234567/sp/0/playManifest/entryId/#{entry_id}/format/url/protocol/https/flavorId/487071/name/#{stream.title}.mp4"
        expect(stream.sd_download_url).to eq "https://cdnapisec.kaltura.com/p/4549393/sp/454939300/playManifest/entryId/#{entry_id}/format/download/protocol/https/flavorParamIds/487071"
        expect(stream.sd_size).to eq size
        expect(stream.hls_url).to eq "https://cdnapisec.kaltura.com/p/1234567/sp/0/playManifest/entryId/#{entry_id}/format/applehttp/protocol/https/flavorId/487071/name/#{stream.title}"
      end
    end

    context 'with multiple flavor options for a quality' do
      before do
        xi_config <<~YML
          kaltura:
            api_url: https://www.kaltura.com
            asset_url: https://cdnapisec.kaltura.com/p
            flavors:
              source: 0
              sd: [487061, 487071]
              hd: 487091
        YML
      end

      it 'picks the first matching flavor option for the SD streams' do
        sync

        # Video 1_jrdhwl7x has the 487061 flavor
        expect(Video::Stream.find_by(provider_video_id: '1_jrdhwl7x').sd_url).to include('487061')

        # Video 1_onu0bd7k hasn't
        expect(Video::Stream.find_by(provider_video_id: '1_onu0bd7k').sd_url).to include('487071')
      end
    end

    context 'without a matching flavor for one video' do
      before do
        xi_config <<~YML
          kaltura:
            api_url: https://www.kaltura.com
            asset_url: https://cdnapisec.kaltura.com/p
            flavors:
              source: 0
              sd: 487051
              hd: 487091
        YML
      end

      # Video 1_vk282t4e doesn't have the 487051 flavor
      it 'gracefully only creates 2 streams' do
        expect { sync }.to change(Video::Stream, :count).from(0).to(2)

        expect(Video::Stream.find_by(provider_video_id: '1_vk282t4e')).to be_nil
      end
    end

    describe '(partial sync)' do
      subject(:partial_sync) { adapter.sync(since: provider.synchronized_at, full: false) }

      let(:provider) do
        create(:video_provider, :kaltura,
          synchronized_at: 2.hours.ago,
          credentials: {
            'partner_id' => 1_234_567,
            'token_id' => '1_rjbgukyi',
            'token' => 'a819271b6406e02d54b70da54bb906a5',
          })
      end
      let!(:media_list_request) do
        stub_request(:post, 'https://www.kaltura.com/api_v3/service/media/action/list')
          .with(body: hash_including(
            filter: hash_including('createdAtGreaterThanOrEqual' => provider.synchronized_at.to_i),
            ks: kaltura_session_token
          )).to_return(
            status: 200,
            body: media_entries_response,
            headers: {'Content-Type' => 'text/xml;charset=UTF-8'}
          )
      end

      it 'calls the Kaltura API services' do
        partial_sync
        expect(media_list_request).to have_been_requested.once
      end

      it 'stores the new streams from Kaltura' do
        expect { partial_sync }.to change(Video::Stream, :count).from(0).to(3)
      end
    end
  end

  describe '#sync_single' do
    subject(:sync_single) { adapter.sync_single(provider_video_id) }

    let(:provider_video_id) { '1_jrdhwl7x' }
    let!(:stream) { create(:stream, provider:, provider_video_id:) }
    let(:single_media_entry_response) { File.read('./spec/support/files/video/kaltura/media_entry.xml') }

    let!(:flavor_asset_request) do
      stub_request(:post, 'https://www.kaltura.com/api_v3/service/flavorasset/action/getFlavorAssetsWithParams')
        .with(body: hash_including(entryId: '1_jrdhwl7x'))
        .to_return(status: 200, body: flavor_asset_1, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})
    end
    let!(:media_entry_request) do
      stub_request(:post, 'https://www.kaltura.com/api_v3/service/media/action/get')
        .with(body: hash_including(
          entryId: '1_jrdhwl7x',
          ks: kaltura_session_token
        )).to_return(status: 200, body: single_media_entry_response, headers: {'Content-Type' => 'text/xml;charset=UTF-8'})
    end

    it 'calls the Kaltura API services for just one entry' do
      sync_single
      expect(media_entry_request).to have_been_requested.once
      expect(flavor_asset_request).to have_been_requested.once
    end

    it 'does not store a new stream' do
      expect { sync_single }.not_to change(Video::Stream, :count).from(1)
    end

    it 'updates the stream data from remote' do
      expect do
        sync_single
        stream.reload
      end.to change(stream, :title).to('webtech2021-kombi-teaser-lecturer')
        .and change(stream, :poster).to('https://cfvod.kaltura.com/p/4549393/sp/454939300/thumbnail/entry_id/1_jrdhwl7x/version/100001/width/1280')
    end
  end
end
