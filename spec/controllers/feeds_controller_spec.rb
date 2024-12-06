# frozen_string_literal: true

require 'spec_helper'

describe FeedsController, type: :controller do
  let(:json) { response.parsed_body }

  before do
    Stub.service(:course, build(:'course:root'))
  end

  describe '#index' do
    subject(:index) { get :index }

    context 'with no params' do
      it 'answers with a page' do
        index
        expect(response).to have_http_status :ok
      end
    end
  end

  describe '#show' do
    subject(:show) { get :courses, params: {format: :json} }

    before do
      Stub.request(
        :course, :get, '/courses',
        query: {public: 'true', hidden: 'false', per_page: 250}
      ).to_return Stub.json([
        {
          id: '00000001-636e-4444-9999-000000000044',
          course_code: 'my-course',
          title: 'My course',
          description: 'hello world',
          status: 'archived',
          classifiers: {
            category: %w[cat1 cat2 dup],
            topic: %w[topic1 topic2 dup],
            reporting: %w[other1 other2],
          },
        }, {
          id: '00000001-636e-4444-9999-000000000045',
          course_code: 'my-second-course',
          title: 'My second course',
          description: 'hello world',
          status: 'active',
          classifiers: {
            category: %w[cat1 cat2 dup],
            topic: %w[topic1 topic2 dup],
            reporting: %w[other1 other2],
          },
        }
      ])
    end

    context 'with no extra params' do
      it 'responds with JSON' do
        show
        expect(response).to have_http_status :ok

        expect(json['courses'][0]['id']).to eq '00000001-636e-4444-9999-000000000044'
        expect(json['courses'][0]['title']).to eq 'My course'
        expect(json['courses'][0]['status']).to eq 'archived'

        expect(json['courses'][1]['id']).to eq '00000001-636e-4444-9999-000000000045'
        expect(json['courses'][1]['title']).to eq 'My second course'
        expect(json['courses'][1]['status']).to eq 'active'
      end

      describe '[categories]' do
        subject(:categories) do
          show
          json['courses'][0]['categories']
        end

        it 'munges together all classifiers' do
          expect(categories).to all(be_a(String))
        end

        it 'only uses the "category" and "topic" classifiers and ignores duplicates' do
          expect(categories).to eq %w[cat1 cat2 dup topic1 topic2]
        end
      end
    end
  end
end
