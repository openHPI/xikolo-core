# frozen_string_literal: true

require 'spec_helper'

describe NewsService::NewsDecorator do
  let(:news) { create(:'news_service/news') }
  let(:decorator) { described_class.new news }

  context 'as_api_v1' do
    subject { json }

    let(:json) { decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('title') }
    it { is_expected.to include('author_id') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('publish_at') }
    it { is_expected.to include('show_on_homepage') }
    it { is_expected.to include('receivers') }
    it { is_expected.to include('state') }
    it { is_expected.to include('sending_state') }
    it { is_expected.to include('text') }
    it { is_expected.to include('teaser') }

    describe 'externalize_file_refs' do
      context 'with s3:// URIs in the text' do
        before do
          news.translations.first.update!(
            text: "<p>Look at this image:</p>\n" \
                  '<img src="s3://xikolo-public/news/4h6o13Rq87Ds5AnF78q28j_image.png" alt="Test image">'
          )
        end

        it 'converts s3:// URIs to HTTP URLs' do
          expect(json['text']).not_to include('s3://')
          expect(json['text']).to match(%r{http://.*xikolo-public/news/4h6o13Rq87Ds5AnF78q28j_image\.png})
        end

        it 'preserves the original markup and attributes' do
          expect(json['text']).to include('img')
          expect(json['text']).to include('alt="Test image"')
        end
      end

      context 'with multiple s3:// URIs in the text' do
        before do
          news.translations.first.update!(
            text: "<img src='s3://xikolo-public/news/aaa_image1.png'>" \
                  '<p>Text between</p>' \
                  "<img src='s3://xikolo-public/news/bbb_image2.png'>"
          )
        end

        it 'externalizes all references' do
          expect(json['text']).not_to include('s3://')
          expect(json['text']).to match(%r{http://.*xikolo-public/news/aaa_image1\.png})
          expect(json['text']).to match(%r{http://.*xikolo-public/news/bbb_image2\.png})
        end
      end

      context 'with no s3:// URIs' do
        before do
          news.translations.first.update!(text: '<p>Plain text without images</p>')
        end

        it 'returns the text unchanged' do
          expect(json['text']).to eq '<p>Plain text without images</p>'
        end
      end

      context 'in embedded translations' do
        before do
          news.translations.create!(
            locale: 'de',
            title: 'Test',
            text: '<img src="s3://xikolo-public/news/de_image.png">'
          )
        end

        it 'externalizes s3:// URIs in other translations too' do
          embedded_decorator = described_class.new(news, context: {embed: 'translations', language: 'en'})
          embedded_json = embedded_decorator.as_json(api_version: 1).stringify_keys
          expect(embedded_json['translations']['de']['text']).not_to include('s3://')
          expect(embedded_json['translations']['de']['text']).to include('http:')
        end
      end
    end

    describe 'creating a teaser' do
      context 'with no teaser given' do
        context 'with more than five lines of text' do
          let(:news) { create(:'news_service/news', :with_many_lines, num_lines: 10) }

          it 'uses the first five lines as teaser' do
            expect(json['teaser'].lines.count).to eq 5
          end
        end

        context 'with less than five lines of text' do
          let(:news) { create(:'news_service/news', :with_many_lines, num_lines: 3) }

          it 'uses the full text as teaser' do
            expect(json['teaser'].lines.count).to eq 3
          end
        end
      end

      context 'with a given teaser' do
        let(:news) { create(:'news_service/news', teaser: 'The teaser') }

        it 'uses the given teaser' do
          expect(json['teaser']).to eq 'The teaser'
        end
      end
    end
  end
end
