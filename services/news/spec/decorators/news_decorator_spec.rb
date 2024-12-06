# frozen_string_literal: true

require 'spec_helper'

describe NewsDecorator do
  let(:news) { create(:news) }
  let(:decorator) { described_class.new news }

  context 'as_api_v1' do
    subject { json }

    let(:json) { decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('title') }
    it { is_expected.to include('author_id') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('publish_at') }
    it { is_expected.to include('visual_url') }
    it { is_expected.to include('show_on_homepage') }
    it { is_expected.to include('receivers') }
    it { is_expected.to include('state') }
    it { is_expected.to include('sending_state') }
    it { is_expected.to include('text') }
    it { is_expected.to include('teaser') }

    describe 'creating a teaser' do
      context 'with no teaser given' do
        context 'with more than five lines of text' do
          let(:news) { create(:news, :with_many_lines, num_lines: 10) }

          it 'uses the first five lines as teaser' do
            expect(json['teaser'].lines.count).to eq 5
          end
        end

        context 'with less than five lines of text' do
          let(:news) { create(:news, :with_many_lines, num_lines: 3) }

          it 'uses the full text as teaser' do
            expect(json['teaser'].lines.count).to eq 3
          end
        end
      end

      context 'with a given teaser' do
        let(:news) { create(:news, teaser: 'The teaser') }

        it 'uses the given teaser' do
          expect(json['teaser']).to eq 'The teaser'
        end
      end
    end
  end
end
