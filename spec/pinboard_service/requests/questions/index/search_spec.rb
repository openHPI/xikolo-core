# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /questions{?search}', type: :request do
  # NOTE: Specs will fail if the course id is not given as otherwise
  # no english stemming would be used for the search term. Without
  # english stemming there would be no match.
  subject(:response) do
    api.rel(:questions).get({search: query, course_id:}).value!
  end

  let(:api) { restify_with_headers(pinboard_service_url).get.value! }
  let(:query) { 'token' }
  let(:course_id) { generate(:course_id) }

  let!(:q1) do
    create(:'pinboard_service/question',
      title: 'A simple question',
      text: 'With a very satisfied text',
      course_id:)
  end

  let!(:q2) do
    create(:'pinboard_service/question',
      title: 'A not-matching question',
      text: 'With a non-matching text answer to this question',
      course_id:)
  end

  let!(:q3) do
    create(:'pinboard_service/question',
      title: 'A simple question title',
      text: 'With an answer text in specific order.',
      course_id:)
  end

  let!(:q4) do
    create(:'pinboard_service/question',
      title: 'A simple question title',
      text: 'With order of specific answer text.',
      course_id:)
  end

  before do
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({course_code: 'code2019', lang: 'en'})

    # Ensure above scheduled workers are run to build the search index
    PinboardService::UpdateQuestionSearchTextWorker.drain
  end

  it { is_expected.to respond_with :ok }

  describe 'results' do
    subject(:results) { response.pluck('id') }

    context 'with positive match' do
      # tests matching and stemming
      let(:query) { 'satisfying' }

      it { is_expected.to eq [q1.id] }
    end

    context 'with negative match' do
      let(:query) { '-simple' }

      it { is_expected.to eq [q2.id] }
    end

    context 'with multiple terms' do
      let(:query) { 'specific order' }

      it { is_expected.to contain_exactly(q3.id, q4.id) }
    end

    context 'with quoted search term' do
      let(:query) { '"specific order"' }

      it { is_expected.to eq [q3.id] }
    end

    context 'with alternative' do
      let(:query) { 'satisfied or non-matching' }

      it { is_expected.to contain_exactly(q1.id, q2.id) }
    end

    context 'with ranking' do
      let(:query) { 'question' }

      it 'returns with best match first' do
        # Q2 is matched in title and text
        expect(results.first).to eq q2.id
      end

      it 'returns equally ranks by sort clause (default updated_at)' do
        # Q2 is matched in title and text
        expect(results[1..]).to eq [q4.id, q3.id, q1.id]
      end
    end
  end
end
