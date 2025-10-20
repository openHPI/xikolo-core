# frozen_string_literal: true

require 'spec_helper'

describe 'Repetition Suggestions: Index', type: :request do
  subject(:list) do
    api.rel(:repetition_suggestions).get(params).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:user_id) { generate(:user_id) }
  let(:max_dpoints) { 100 }
  let(:course_id) { '00000001-3300-4444-9999-000000000001' }
  let!(:course) { create(:'course_service/course', id: course_id) }
  let!(:section) { create(:'course_service/section', course:) }
  let!(:items) { create_list(:'course_service/item', 5, :quiz, section:, max_dpoints:) }
  let(:result_1) { create(:'course_service/result', user_id:, item: items[0], dpoints: 10) }
  let(:result_2) { create(:'course_service/result', user_id:, item: items[1], dpoints: 60) }
  let(:result_3) { create(:'course_service/result', user_id:, item: items[2], dpoints: 50) }
  let(:params) { {} }

  before { result_1; result_2; result_3 }

  context 'without course_id provided' do
    it 'returns 422 Unprocessible Entity' do
      expect { list }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
      end
    end
  end

  context 'without user_id provided' do
    let(:params) { super().merge course_id: }

    it 'returns 422 Unprocessible Entity' do
      expect { list }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
      end
    end
  end

  context 'with required parameters' do
    let(:params) do
      super().merge(
        course_id:,
        user_id:,
        content_type: 'quiz',
        exercise_type: 'selftest',
        limit: 3
      )
    end

    it 'returns the items in the correct order' do
      expect(list.pluck('id')).to eq [result_1, result_3, result_2].map {|r| r.item.id }
    end

    it 'returns the item resources with decorated attributes' do
      expect(list.first.to_h).to include \
        'id'                => result_1.item.id,
        'course_id'         => result_1.item.course_id,
        'section_id'        => result_1.item.section_id,
        'title'             => result_1.item.title,
        'user_points'       => 1.0,
        'max_points'        => 10.0,
        'points_percentage' => 10
    end

    context 'with results better than threshold' do
      let(:result_1) { create(:'course_service/result', user_id:, item: items[0], dpoints: 80) }
      let(:result_3) { create(:'course_service/result', user_id:, item: items[2], dpoints: 90) }

      it 'returns only items with performance below the threshold' do
        expect(list.size).to eq 1
        expect(list.first.to_h).to include \
          'id'                => result_2.item.id,
          'course_id'         => result_2.item.course_id,
          'section_id'        => result_2.item.section_id,
          'title'             => result_2.item.title,
          'user_points'       => 6.0,
          'max_points'        => 10.0,
          'points_percentage' => 60
      end
    end

    context 'with more than three results' do
      before do
        create(:'course_service/result', user_id:, item: items[3], dpoints: 65)
        create(:'course_service/result', user_id:, item: items[4], dpoints: 90)
      end

      it 'returns a maximum of three results' do
        expect(list.size).to eq 3
      end
    end

    context 'with results for other item/quiz types' do
      let!(:homework) { create(:'course_service/item', :homework, section:, max_dpoints:) }

      before { create(:'course_service/result', user_id:, item: homework, dpoints: 5) }

      it 'does not include the item' do
        expect(list.pluck('id')).to eq [result_1, result_3, result_2].map {|r| r.item.id }
      end
    end

    context 'with items of different courses' do
      let(:course_id_2) { '00000001-3300-4444-9999-000000000002' }
      let!(:course_2) { create(:'course_service/course', id: course_id_2) }
      let!(:section_2) { create(:'course_service/section', course: course_2) }
      let!(:other_course_item) { create(:'course_service/item', :quiz, section: section_2, max_dpoints:) }

      before { create(:'course_service/result', user_id:, item: other_course_item, dpoints: 5) }

      it 'does not include the item' do
        expect(list.pluck('id')).to eq [result_1, result_3, result_2].map {|r| r.item.id }
      end
    end

    context 'with more than one result for an item' do
      before { create(:'course_service/result', user_id:, item: items[0], dpoints: 5) }

      it 'does return the according item only once' do
        expect(list.pluck('id')).to eq [result_1, result_3, result_2].map {|r| r.item.id }
      end

      it 'does take the better result' do
        expect(list.first.to_h['user_points']).to eq 1.0
      end
    end

    context 'with item not available' do
      let!(:item_unpublished) { create(:'course_service/item', :quiz, section:, max_dpoints:, published: false) }

      before { create(:'course_service/result', user_id:, item: item_unpublished, dpoints: 5) }

      it 'does not return the unpublished item' do
        expect(list.pluck('id')).to eq [result_1, result_3, result_2].map {|r| r.item.id }
      end
    end
  end
end
