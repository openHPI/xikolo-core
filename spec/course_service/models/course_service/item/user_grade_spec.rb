# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, '#user_grade' do
  subject(:item) { create(:'course_service/item', *item_traits) }

  let(:item_traits) { [] }
  let(:user_id) { create(:'account_service/user').id }
  let(:grade) { item.user_grade(user_id) }

  context 'a "normal" item (e.g. video)' do
    it 'does not support user grades' do
      expect(item).not_to be_graded
    end

    it 'errors when trying to access the user grade' do
      expect { grade }.to raise_error(CourseService::Item::NotGradedError)
    end
  end

  context 'a selftest' do
    let(:item_traits) { %i[quiz] }

    it 'does not support user grades' do
      expect(item).not_to be_graded
    end

    it 'errors when trying to access the user grade' do
      expect { grade }.to raise_error(CourseService::Item::NotGradedError)
    end
  end

  context 'a homework' do
    let(:item_traits) { %i[homework] }

    it 'supports user grades' do
      expect(item).to be_graded
    end

    it 'returns nil when there are no results for the user' do
      item.results.create!(user: create(:'account_service/user'), dpoints: 40)

      expect(grade).to be_nil
    end

    it 'returns the user\'s best result' do
      item.results.create!(user: create(:'account_service/user'), dpoints: 40)
      my_best = item.results.create!(user_id:, dpoints: 30)
      item.results.create!(user_id:, dpoints: 15)
      item.results.create!(user_id:, dpoints: 20)

      expect(grade).to eq my_best
    end
  end

  context 'a bonus exercise' do
    let(:item_traits) { %i[bonus] }

    it 'supports user grades' do
      expect(item).to be_graded
    end

    it 'returns the user\'s best result' do
      item.results.create!(user: create(:'account_service/user'), dpoints: 40)
      my_best = item.results.create!(user_id:, dpoints: 30)
      item.results.create!(user_id:, dpoints: 15)
      item.results.create!(user_id:, dpoints: 20)

      expect(grade).to eq my_best
    end
  end
end
