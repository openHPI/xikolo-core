# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ItemStatistics: Show', type: :request do
  subject(:show) do
    api
      .rel(:item).get(item_params).value!
      .rel(:statistics).get(statistics_params).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:item) { create(:'course_service/item') }
  let(:item_params) { {id: item.id} }
  let(:statistics_params) { {} }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it 'includes all base stats' do
      expect(show).to include(
        'total_submissions',
        'total_submissions_distinct',
        'perfect_submissions',
        'perfect_submissions_distinct',
        'max_points',
        'avg_points'
      )
    end

    it 'does not include any other stats' do
      expect(show).not_to include(
        'submissions_over_time'
      )
    end
  end

  context 'embed' do
    context 'submissions_over_time' do
      let(:statistics_params) { super().merge(embed: 'submissions_over_time') }

      it { expect(show).to include('submissions_over_time') }
    end

    context 'unsupported statistic' do
      let(:statistics_params) { super().merge(embed: 'unsupported') }

      it 'returns a 404' do
        expect { show }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end

  context 'only' do
    subject(:keys) { show.keys }

    context 'submissions_over_time' do
      let(:statistics_params) { super().merge(only: 'submissions_over_time') }

      it { expect(keys).to contain_exactly('submissions_over_time') }
    end

    context 'unsupported statistic' do
      let(:statistics_params) { super().merge(only: 'unsupported') }

      it 'returns a 404' do
        expect { show }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end
end
