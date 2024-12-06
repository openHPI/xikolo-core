# frozen_string_literal: true

require 'spec_helper'

describe SitemapSupport do
  describe '.video_sitemap' do
    subject(:video_sitemap) do
      described_class.video_sitemap(stream, title, description)
    end

    let(:title) { 'A title' }
    let(:description) { 'A description' }
    let(:stream_params) { {duration: 30} }

    context 'for a Vimeo stream' do
      let(:stream) { create(:stream, :vimeo, :with_downloads, stream_params) }

      it 'creates correct links' do
        expect(video_sitemap).to match hash_including(
          title: 'A title',
          description: 'A description',
          content_loc: "https://xikolo.de/streams/#{UUID4(stream.id).to_s(format: :base62)}/downloads/hd",
          thumbnail_loc: 'http://hd.stream.url/poster.jpg',
          duration: 30
        )
      end

      context 'without HD download stream' do
        let(:stream_params) { super().merge(hd_download_url: nil) }

        it 'chooses the SD download stream' do
          expect(video_sitemap).to match hash_including(
            title: 'A title',
            description: 'A description',
            content_loc: "https://xikolo.de/streams/#{UUID4(stream['id']).to_s(format: :base62)}/downloads/sd",
            thumbnail_loc: 'http://hd.stream.url/poster.jpg',
            duration: 30
          )
        end
      end
    end

    context 'for a Kaltura stream' do
      let(:stream) { create(:stream, :kaltura, :with_downloads, stream_params) }

      it 'creates correct links' do
        expect(video_sitemap).to match hash_including(
          title: 'A title',
          description: 'A description',
          content_loc: "https://xikolo.de/streams/#{UUID4(stream['id']).to_s(format: :base62)}/downloads/hd",
          thumbnail_loc: 'http://hd.stream.url/poster.jpg',
          duration: 30
        )
      end

      context 'without HD download stream' do
        let(:stream_params) { super().merge(hd_download_url: nil) }

        it 'chooses SD download stream' do
          expect(video_sitemap).to match hash_including(
            title: 'A title',
            description: 'A description',
            content_loc: "https://xikolo.de/streams/#{UUID4(stream['id']).to_s(format: :base62)}/downloads/sd",
            thumbnail_loc: 'http://hd.stream.url/poster.jpg',
            duration: 30
          )
        end
      end
    end
  end
end
