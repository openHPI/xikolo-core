# frozen_string_literal: true

require 'spec_helper'

describe ItemStatistics do
  subject { stats }

  before do
    user_1_id = generate(:user_id)
    user_2_id = generate(:user_id)

    create(:result,
      item_id: item.id,
      user_id: user_1_id,
      dpoints: 40,
      created_at: DateTime.new(2000, 1, 1, 10))
    create(:result,
      item_id: item.id,
      user_id: user_1_id,
      dpoints: 100,
      created_at: DateTime.new(2000, 1, 1, 11))
    create(:result,
      item_id: item.id,
      user_id: user_2_id,
      dpoints: 50,
      created_at: DateTime.new(2000, 1, 2, 12))

    # create another item with results that should be ignored
    other_item = create(:item, :quiz, max_dpoints: 150)
    create(:result,
      item_id: other_item.id,
      user_id: user_1_id,
      dpoints: 60,
      created_at: DateTime.new(2000, 1, 1, 10))
    create(:result,
      item_id: other_item.id,
      user_id: user_1_id,
      dpoints: 150,
      created_at: DateTime.new(2000, 1, 1, 11))
    create(:result,
      item_id: other_item.id,
      user_id: user_2_id,
      dpoints: 75,
      created_at: DateTime.new(2000, 1, 2, 12))
  end

  let(:item) { create(:item, :quiz, max_dpoints: 100) }
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

  describe 'submissions_over_time' do
    subject(:s_o_t) { stats.submissions_over_time }

    it 'includes timestamps per hour with counts' do
      expect(s_o_t.as_json).to include(
        '2000-01-01 10:00:00 UTC' => 1,
        '2000-01-01 11:00:00 UTC' => 1,
        '2000-01-01 12:00:00 UTC' => 0,
        '2000-01-01 13:00:00 UTC' => 0,
        '2000-01-01 14:00:00 UTC' => 0,
        '2000-01-01 15:00:00 UTC' => 0,
        '2000-01-01 16:00:00 UTC' => 0,
        '2000-01-01 17:00:00 UTC' => 0,
        '2000-01-01 18:00:00 UTC' => 0,
        '2000-01-01 19:00:00 UTC' => 0,
        '2000-01-01 20:00:00 UTC' => 0,
        '2000-01-01 21:00:00 UTC' => 0,
        '2000-01-01 22:00:00 UTC' => 0,
        '2000-01-01 23:00:00 UTC' => 0,
        '2000-01-02 00:00:00 UTC' => 0,
        '2000-01-02 01:00:00 UTC' => 0,
        '2000-01-02 02:00:00 UTC' => 0,
        '2000-01-02 03:00:00 UTC' => 0,
        '2000-01-02 04:00:00 UTC' => 0,
        '2000-01-02 05:00:00 UTC' => 0,
        '2000-01-02 06:00:00 UTC' => 0,
        '2000-01-02 07:00:00 UTC' => 0,
        '2000-01-02 08:00:00 UTC' => 0,
        '2000-01-02 09:00:00 UTC' => 0,
        '2000-01-02 10:00:00 UTC' => 0,
        '2000-01-02 11:00:00 UTC' => 0,
        '2000-01-02 12:00:00 UTC' => 1
      )
    end

    context 'with more than three days' do
      before do
        user_id = generate(:user_id)

        create(:result,
          item_id: item.id,
          user_id:,
          dpoints: 60,
          created_at: DateTime.new(2000, 1, 3, 10))
        create(:result,
          item_id: item.id,
          user_id:,
          dpoints: 75,
          created_at: DateTime.new(2000, 1, 6, 11))
      end

      it 'includes timestamps per day with counts' do
        expect(s_o_t.as_json).to include(
          '2000-01-01' => 2,
          '2000-01-02' => 1,
          '2000-01-03' => 1,
          '2000-01-04' => 0,
          '2000-01-05' => 0,
          '2000-01-06' => 1
        )
      end
    end
  end
end
