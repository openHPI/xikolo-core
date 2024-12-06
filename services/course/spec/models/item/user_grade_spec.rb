# frozen_string_literal: true

require 'spec_helper'

describe Item, '#user_grade' do
  subject(:item) { create(:item, *item_traits) }

  let(:item_traits) { [] }
  let(:user_id) { generate(:user_id) }
  let(:grade) { item.user_grade(user_id) }

  context 'a "normal" item (e.g. video)' do
    it 'does not support user grades' do
      expect(item).not_to be_graded
    end

    it 'errors when trying to access the user grade' do
      expect { grade }.to raise_error(Item::NotGradedError)
    end
  end

  context 'a selftest' do
    let(:item_traits) { %i[quiz] }

    it 'does not support user grades' do
      expect(item).not_to be_graded
    end

    it 'errors when trying to access the user grade' do
      expect { grade }.to raise_error(Item::NotGradedError)
    end
  end

  context 'a homework' do
    let(:item_traits) { %i[homework] }

    it 'supports user grades' do
      expect(item).to be_graded
    end

    it 'returns nil when there are no results for the user' do
      item.user_results.create(user_id: generate(:user_id), dpoints: 40)

      expect(grade).to be_nil
    end

    it 'returns the user\'s best result' do
      item.user_results.create(user_id: generate(:user_id), dpoints: 40)
      my_best = item.user_results.create(user_id:, dpoints: 30)
      item.user_results.create(user_id:, dpoints: 15)
      item.user_results.create(user_id:, dpoints: 20)

      expect(grade).to eq my_best
    end

    context 'when the user is enrolled and booked proctoring' do
      before { item.section.course.enrollments.create(user_id:, proctored: true) }

      it 'still returns the user\'s best result' do
        item.user_results.create(user_id: generate(:user_id), dpoints: 40)
        my_best = item.user_results.create(user_id:, dpoints: 30)
        item.user_results.create(user_id:, dpoints: 15)
        item.user_results.create(user_id:, dpoints: 20)

        expect(grade).to eq my_best
      end
    end
  end

  context 'a proctored homework' do
    let(:item_traits) { %i[homework proctored] }

    it 'supports user grades' do
      expect(item).to be_graded
    end

    it 'returns the user\'s best result by default' do
      item.user_results.create(user_id: generate(:user_id), dpoints: 40)
      my_best = item.user_results.create(user_id:, dpoints: 30)
      item.user_results.create(user_id:, dpoints: 15)
      item.user_results.create(user_id:, dpoints: 20)

      expect(grade).to eq my_best
    end

    context 'when the user is enrolled, but not proctored' do
      before { item.section.course.enrollments.create(user_id:) }

      it 'returns the user\'s best result' do
        item.user_results.create(user_id: generate(:user_id), dpoints: 40)
        my_best = item.user_results.create(user_id:, dpoints: 30)
        item.user_results.create(user_id:, dpoints: 15)
        item.user_results.create(user_id:, dpoints: 20)

        expect(grade).to eq my_best
      end
    end

    context 'when the user is enrolled and booked proctoring' do
      before { item.section.course.enrollments.create(user_id:, proctored: true) }

      it 'returns the user\'s latest result' do
        item.user_results.create!(user_id: generate(:user_id), dpoints: 40, created_at: 3.minutes.ago)
        item.user_results.create!(user_id:, dpoints: 30, created_at: 5.minutes.ago)
        item.user_results.create!(user_id:, dpoints: 15, created_at: 4.minutes.ago)
        my_latest = item.user_results.create!(user_id:, dpoints: 20, created_at: 3.minutes.ago)

        expect(grade).to eq my_latest
      end
    end
  end

  context 'a bonus exercise' do
    let(:item_traits) { %i[bonus] }

    it 'supports user grades' do
      expect(item).to be_graded
    end

    it 'returns the user\'s best result' do
      item.user_results.create(user_id: generate(:user_id), dpoints: 40)
      my_best = item.user_results.create(user_id:, dpoints: 30)
      item.user_results.create(user_id:, dpoints: 15)
      item.user_results.create(user_id:, dpoints: 20)

      expect(grade).to eq my_best
    end

    context 'when the user is enrolled and booked proctoring' do
      before { item.section.course.enrollments.create(user_id:, proctored: true) }

      it 'still returns the user\'s best result' do
        item.user_results.create(user_id: generate(:user_id), dpoints: 40)
        my_best = item.user_results.create(user_id:, dpoints: 30)
        item.user_results.create(user_id:, dpoints: 15)
        item.user_results.create(user_id:, dpoints: 20)

        expect(grade).to eq my_best
      end
    end
  end
end
