# frozen_string_literal: true

require 'spec_helper'

describe CourseService::ItemStatistics do
  subject { stats }

  before do
    user_1_id = generate(:user_id)
    user_2_id = generate(:user_id)

    create(:'course_service/result',
      item_id: item.id,
      user_id: user_1_id,
      dpoints: 40,
      created_at: DateTime.new(2000, 1, 1, 10))
    create(:'course_service/result',
      item_id: item.id,
      user_id: user_1_id,
      dpoints: 100,
      created_at: DateTime.new(2000, 1, 1, 11))
    create(:'course_service/result',
      item_id: item.id,
      user_id: user_2_id,
      dpoints: 50,
      created_at: DateTime.new(2000, 1, 2, 12))

    # create another item with results that should be ignored
    other_item = create(:'course_service/item', :quiz, max_dpoints: 150)
    create(:'course_service/result',
      item_id: other_item.id,
      user_id: user_1_id,
      dpoints: 60,
      created_at: DateTime.new(2000, 1, 1, 10))
    create(:'course_service/result',
      item_id: other_item.id,
      user_id: user_1_id,
      dpoints: 150,
      created_at: DateTime.new(2000, 1, 1, 11))
    create(:'course_service/result',
      item_id: other_item.id,
      user_id: user_2_id,
      dpoints: 75,
      created_at: DateTime.new(2000, 1, 2, 12))
  end

  let(:item) { create(:'course_service/item', :quiz, max_dpoints: 100) }
  let(:stats) { item.stats }

  describe 'total_submissions' do
    subject { super().total_submissions }

    it { is_expected.to eq(3) }
  end

  describe 'total_submissions_distinct' do
    subject { super().total_submissions_distinct }

    it { is_expected.to eq(2) }
  end

  describe 'perfect_submissions' do
    subject { super().perfect_submissions }

    it { is_expected.to eq(1) }
  end

  describe 'perfect_submissions_distinct' do
    subject { super().perfect_submissions_distinct }

    it { is_expected.to eq(1) }
  end

  describe 'max_points' do
    subject { super().max_points }

    it { is_expected.to eq(10.0) }
  end

  describe 'avg_points' do
    subject { super().avg_points }

    it { is_expected.to eq(6.33) }
  end
end
