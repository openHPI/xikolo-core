# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SubmissionStatistics: Show', type: :request do
  subject(:show) { api.rel(:submission_statistic).get(params).value! }

  let(:api) { Restify.new(quiz_service_url).get.value! }
  let(:quiz) { create(:'quiz_service/quiz') }
  let(:params) { {id: quiz.id} }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it do
      expect(show).to include(
        'total_submissions',
        'total_submissions_distinct',
        'max_points',
        'avg_points',
        'unlimited_time'
      )
    end

    it do
      expect(show).not_to include(
        'avg_submit_duration',
        'box_plot_distributions',
        'questions_base_stats'
      )
    end
  end

  context 'embed' do
    context 'avg_submit_duration' do
      let(:params) { super().merge(embed: 'avg_submit_duration') }

      it { expect(show).to include('avg_submit_duration') }
    end

    context 'box_plot_distributions' do
      let(:params) { super().merge(embed: 'box_plot_distributions') }

      it { expect(show).to include('box_plot_distributions') }
    end

    context 'questions_base_stats' do
      let(:params) { super().merge(embed: 'questions_base_stats') }

      it { expect(show).to include('questions_base_stats') }
    end

    context 'all' do
      let(:params) do
        super().merge(
          embed: %w[
            avg_submit_duration
            box_plot_distributions
            questions_base_stats
          ].join(',')
        )
      end

      it do
        expect(show).to include(
          'avg_submit_duration',
          'box_plot_distributions',
          'questions_base_stats'
        )
      end
    end

    context 'unsupported statistic' do
      let(:params) { super().merge(embed: 'unsupported') }

      it 'returns a 404' do
        expect { show }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end

  context 'only' do
    subject(:keys) { show.keys }

    context 'avg_submit_duration' do
      let(:params) { super().merge(only: 'avg_submit_duration') }

      it { expect(keys).to contain_exactly('avg_submit_duration') }
    end

    context 'box_plot_distributions' do
      let(:params) { super().merge(only: 'box_plot_distributions') }

      it { expect(keys).to contain_exactly('box_plot_distributions') }
    end

    context 'questions_base_stats' do
      let(:params) { super().merge(only: 'questions_base_stats') }

      it { expect(keys).to contain_exactly('questions_base_stats') }
    end

    context 'unsupported statistic' do
      let(:params) { super().merge(only: 'unsupported') }

      it 'returns a 404' do
        expect { show }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end
end
