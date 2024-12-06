# frozen_string_literal: true

require 'spec_helper'

describe Course, '#goals', type: :model do
  subject(:goals) { course.goals }

  let(:course) { create(:course) }

  describe '#max_visits' do
    subject(:max_visits) { goals.max_visits }

    context 'without sections and items' do
      it { is_expected.to eq 0 }
    end

    context 'with an empty section' do
      before do
        create(:section, course:)
      end

      it 'ignores empty sections' do
        expect(max_visits).to eq 0
      end
    end

    context 'with a section with three items' do
      before do
        create(:section, course:).tap do |section|
          create_list(:item, 3, section:)
        end
      end

      it { is_expected.to eq 3 }
    end

    context 'with multiple sections with items' do
      let(:section1) { create(:section, course:) }

      before do
        create_list(:item, 2, section: section1)
        create(:section, course:).tap do |section2|
          create_list(:item, 3, section: section2)
        end
      end

      it 'counts items across sections' do
        expect(max_visits).to eq 5
      end

      context 'with items in other courses' do
        before { create(:item) }

        it 'ignores those other items' do
          expect(max_visits).to eq 5
        end
      end

      context 'with optional items' do
        before { section1.items.first.update(optional: true) }

        it 'does not care about visits to those' do
          expect(max_visits).to eq 4
        end
      end

      context 'with an entire section being optional' do
        before { section1.update(optional_section: true) }

        it 'does not care about visits to items in that section, even if they are mandatory' do
          expect(max_visits).to eq 3
        end
      end

      context 'when a section has not been published' do
        let(:section1) { create(:section, course:, published: false) }

        it 'does not care about visits to items in that section' do
          expect(max_visits).to eq 3
        end
      end

      context 'when one of the items has not been published' do
        before do
          section1.items.first.update(published: false)
        end

        it 'does not care about visits to that item' do
          expect(max_visits).to eq 4
        end
      end
    end
  end

  describe '#max_dpoints' do
    subject(:max_dpoints) { goals.max_dpoints }

    context 'without sections and items' do
      it { is_expected.to eq 0 }
    end

    context 'with an empty section' do
      before do
        create(:section, course:)
      end

      it 'ignores empty sections' do
        expect(max_dpoints).to eq 0
      end
    end

    context 'with a section w/ video, selftest, homework and bonus task' do
      let(:section) { create(:section, course:) }

      before do
        create(:item, section:)
        create(:item, :quiz, section:, max_dpoints: 90)
        create(:item, :homework, section:, max_dpoints: 300)
        create(:item, :quiz, :bonus, section:, max_dpoints: 50)
      end

      it 'only sums up points from homeworks' do
        expect(max_dpoints).to eq 300
      end

      context 'when the homework has not been published' do
        before do
          section.items.where(exercise_type: 'main').update_all(published: false)
        end

        it { is_expected.to eq 0 }
      end
    end

    context 'with two sections w/ graded content' do
      let(:section1) { create(:section, course:) }
      let(:section2) { create(:section, course:) }

      before do
        create(:item, section: section1)
        create(:item, :quiz, section: section1, max_dpoints: 90)
        create(:item, :homework, section: section1, max_dpoints: 300)
        create(:item, :quiz, :bonus, section: section1, max_dpoints: 50)

        create(:item, section: section2)
        create(:item, :quiz, section: section2, max_dpoints: 50)
        create(:item, :homework, section: section2, max_dpoints: 600)
        create(:item, :quiz, :bonus, section: section2, max_dpoints: 20)
      end

      it 'sums up points from homeworks across all weeks' do
        expect(max_dpoints).to eq 900
      end

      context 'when one of the sections has not been published' do
        let(:section1) { create(:section, course:, published: false) }

        it 'ignores points from the unpublished one' do
          expect(max_dpoints).to eq 600
        end
      end

      context 'when one of the homeworks has not been published' do
        before do
          section2.items.where(exercise_type: 'main').update_all(published: false)
        end

        it 'ignores points from the unpublished one' do
          expect(max_dpoints).to eq 300
        end
      end
    end
  end
end
