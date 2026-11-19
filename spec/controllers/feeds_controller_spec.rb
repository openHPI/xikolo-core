# frozen_string_literal: true

require 'spec_helper'

describe FeedsController, type: :controller do
  let(:json) { response.parsed_body }
  let(:course_1) { create(:'course_service/course', id: '00000001-636e-4444-9999-000000000044', course_code: 'the_course', title: 'My course') }
  let(:course_2) { create(:'course_service/course', id: '00000001-636e-4444-9999-000000000045', course_code: 'the_second_course', title: 'My second course') }

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
      course_1
      create(:'course_service/cluster', id: 'topic')
      create(:'course_service/cluster', id: 'category')
      course_1.classifiers << create(:'course_service/classifier', cluster_id: 'category', title: 'cat1')
      course_1.classifiers << create(:'course_service/classifier', cluster_id: 'category', title: 'cat2')
      course_1.classifiers << create(:'course_service/classifier', cluster_id: 'topic', title: 'topic1')
      course_1.classifiers << create(:'course_service/classifier', cluster_id: 'topic', title: 'topic2')
      course_1.classifiers << create(:'course_service/classifier', cluster_id: 'topic', title: 'dup')
      course_2
    end

    context 'with no extra params' do
      it 'responds with JSON' do
        show
        expect(response).to have_http_status :ok

        expect(json['courses'][0]['id']).to eq '00000001-636e-4444-9999-000000000044'
        expect(json['courses'][0]['title']).to eq 'My course'
        expect(json['courses'][0]['published']).to be true

        expect(json['courses'][1]['id']).to eq '00000001-636e-4444-9999-000000000045'
        expect(json['courses'][1]['title']).to eq 'My second course'
        expect(json['courses'][1]['published']).to be true
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
