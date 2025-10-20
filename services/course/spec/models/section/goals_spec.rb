# frozen_string_literal: true

require 'spec_helper'

describe Section, '#goals', type: :model do
  subject(:goals) { section.goals(generate(:user_id)) }

  let(:section) { create(:'course_service/section') }

  describe '#max_visits' do
    subject(:max_visits) { goals.max_visits }

    context 'without items' do
      it { is_expected.to eq 0 }
    end

    context 'with three items' do
      before do
        create_list(:'course_service/item', 3, section:)
      end

      it { is_expected.to eq 3 }

      context 'with items in other sections' do
        before { create_list(:'course_service/item', 2) }

        it 'ignores those other items' do
          expect(max_visits).to eq 3
        end
      end

      context 'with optional items' do
        before { section.items.first.update(optional: true) }

        it 'does not care about visits to those' do
          expect(max_visits).to eq 2
        end
      end

      context 'when one of the items has not been published' do
        before do
          section.items.first.update(published: false)
        end

        it 'does not care about visits to that item' do
          expect(max_visits).to eq 2
        end
      end
    end
  end

  describe '#max_dpoints' do
    subject(:max_dpoints) { goals.max_dpoints }

    context 'without items' do
      it { is_expected.to eq 0 }
    end

    context 'with a video, selftest, homework and bonus task' do
      before do
        create(:'course_service/item', section:)
        create(:'course_service/item', :quiz, section:, max_dpoints: 90)
        create(:'course_service/item', :homework, section:, max_dpoints: 300)
        create(:'course_service/item', :quiz, :bonus, section:, max_dpoints: 50)
      end

      it 'only sums up points from homeworks' do
        expect(max_dpoints).to eq 300
      end

      context 'with items in other sections' do
        before { create_list(:'course_service/item', 2, :homework, max_dpoints: 100) }

        it 'ignores those other items' do
          expect(max_dpoints).to eq 300
        end
      end

      context 'when the homework has not been published' do
        before do
          section.items.where(exercise_type: 'main').update_all(published: false)
        end

        it { is_expected.to eq 0 }
      end
    end
  end
end
