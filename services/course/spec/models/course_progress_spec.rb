# frozen_string_literal: true

require 'spec_helper'

describe CourseProgress, type: :model do
  subject(:progress) { described_class.create(course:, user_id:) }

  let!(:course) { create(:'course_service/course') }
  let(:user_id) { generate(:user_id) }

  describe '#points_percentage_fpoints' do
    it { is_expected.to accept_values_for(:points_percentage_fpoints, 0_00, 55_55, 100_00) }
    it { is_expected.not_to accept_values_for(:points_percentage_fpoints, -0_01, 100_01, nil) }
  end

  describe '#visits_percentage_fpoints' do
    it { is_expected.to accept_values_for(:visits_percentage_fpoints, 0_00, 55_55, 100_00) }
    it { is_expected.not_to accept_values_for(:visits_percentage_fpoints, -0_01, 100_01, nil) }
  end

  describe '#calculate!' do
    subject(:calculated) { progress.tap(&:calculate!) }

    context 'without progress in sections' do
      it 'creates an empty progress' do
        expect(calculated).to have_attributes(
          visits: 0,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0,
          max_dpoints: 0,
          max_visits: 0,
          points_percentage_fpoints: 0_00,
          visits_percentage_fpoints: 0_00
        )
      end
    end

    context 'with progress in sections' do
      let(:week1) { create(:'course_service/section', course:) }
      let(:week2) { create(:'course_service/section', course:) }
      let(:week3) { create(:'course_service/section', course:) }
      let(:progress1) do
        create(:'course_service/section_progress', section: week1, user_id:,
          visits: 5,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 20,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2)
      end
      let(:progress2) do
        create(:'course_service/section_progress', section: week2, user_id:,
          visits: 4,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 10,
          selftest_exercises: 1)
      end

      before do
        create_list(:'course_service/item', 5, section: week1)
        create(:'course_service/item', :homework, section: week1, max_dpoints: 50)
        create(:'course_service/item', :quiz, :bonus, section: week1, max_dpoints: 20)
        create_list(:'course_service/item', 2, :quiz, section: week1, max_dpoints: 10)

        create_list(:'course_service/item', 5, section: week2)
        create(:'course_service/item', :homework, section: week2, max_dpoints: 50)
        create(:'course_service/item', :quiz, :bonus, section: week2, max_dpoints: 20)
        create_list(:'course_service/item', 2, :quiz, section: week2, max_dpoints: 10)

        create_list(:'course_service/item', 5, section: week3)
        create(:'course_service/item', :homework, section: week3, max_dpoints: 50)
        create(:'course_service/item', :quiz, :bonus, section: week3, max_dpoints: 20)
        create_list(:'course_service/item', 2, :quiz, section: week3, max_dpoints: 10)

        # The user has visited items in the first two weeks, but not in later ones
        progress1
        progress2

        # Another user has visited the third week
        create(:'course_service/section_progress', section: week3, visits: 2)
      end

      it 'sums up visits, exercises and dpoints from all sections' do
        expect(calculated).to have_attributes(
          visits: 9,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 20,
          bonus_exercises: 1,
          selftest_dpoints: 30,
          selftest_exercises: 3,
          max_dpoints: 150,
          max_visits: 27,
          points_percentage_fpoints: 46_66,
          visits_percentage_fpoints: 33_33
        )
      end

      context 'with perfect score including bonus points' do
        let(:progress2) do
          create(:'course_service/section_progress', section: week2, user_id:,
            visits: 5,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 20,
            selftest_exercises: 2)
        end

        before do
          create(:'course_service/section_progress', section: week3, user_id:,
            visits: 5,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 20,
            selftest_exercises: 2)
        end

        it 'cuts off at 100% even though the total points exceed this value' do
          expect(calculated.points_percentage_fpoints).to eq 100_00
        end
      end

      context 'with complete visits including optional items' do
        let(:progress1) do
          create(:'course_service/section_progress', section: week1, user_id:,
            visits: 10)
        end
        let(:progress2) do
          create(:'course_service/section_progress', section: week2, user_id:,
            visits: 10)
        end

        before do
          create(:'course_service/section_progress', section: week3, user_id:,
            visits: 10)
        end

        it 'cuts off at 100% even though the total visits exceed this value' do
          expect(calculated.visits_percentage_fpoints).to eq 100_00
        end
      end

      context 'with alternative sections' do
        let(:parent_section) { create(:'course_service/section', :parent, course:) }
        let(:alternative_section1) { create(:'course_service/section', :child, course:, parent: parent_section) }
        let(:alternative_section2) { create(:'course_service/section', :child, course:, parent: parent_section) }

        before do
          create(:'course_service/item', :homework, section: alternative_section1, max_dpoints: 50)
          create(:'course_service/item', :quiz, :bonus, section: alternative_section1, max_dpoints: 30)
          create(:'course_service/item', :homework, section: alternative_section2, max_dpoints: 50)
          create(:'course_service/item', :homework, section: alternative_section2, max_dpoints: 10)
          create(:'course_service/item', :quiz, :bonus, section: alternative_section2, max_dpoints: 40)

          create(:'course_service/section_choice',
            section_id: parent_section.id,
            user_id:,
            choice_ids: [alternative_section1.id, alternative_section2.id])

          # Ignored alternative:
          create(:'course_service/section_progress', section: alternative_section1, user_id:,
            visits: 1,
            main_dpoints: 40,
            main_exercises: 1,
            bonus_dpoints: 0,
            bonus_exercises: 0,
            selftest_dpoints: 0,
            selftest_exercises: 0)
          # Graded alternative:
          create(:'course_service/section_progress', section: alternative_section2, user_id:,
            alternative_progress_for: parent_section.id,
            visits: 1,
            main_dpoints: 55,
            main_exercises: 1,
            bonus_dpoints: 0,
            bonus_exercises: 0,
            selftest_dpoints: 0,
            selftest_exercises: 0)
        end

        it 'sums up visits, exercises and dpoints from all sections and the graded alternative section' do
          expect(calculated).to have_attributes(
            visits: 10, # + 1 visit for the item in the alternative section
            main_dpoints: 105, # + 55 for the second alternative section (higher percentage)
            main_exercises: 2, # + 1 for the additional graded quiz from the second alternative section
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 30,
            selftest_exercises: 3,
            max_dpoints: 210, # + 60 for the second alternative section (vs. 50 for the first)
            max_visits: 30, # + 3 for the second alternative section (vs. 2 for the first)
            points_percentage_fpoints: 59_52,
            visits_percentage_fpoints: 33_33
          )
        end
      end

      context 'with fixed learning evaluation' do
        context 'with an empty fixed learning evaluation' do
          before do
            create(:'course_service/fixed_learning_evaluation', course:, user_id:,
              maximal_dpoints: nil, user_dpoints: nil, visits_percentage: nil)
          end

          it 'sums up visits, exercises and dpoints from all sections and ignores fixed evaluation' do
            expect(calculated).to have_attributes(
              visits: 9,
              main_dpoints: 50,
              main_exercises: 1,
              bonus_dpoints: 20,
              bonus_exercises: 1,
              selftest_dpoints: 30,
              selftest_exercises: 3,
              max_dpoints: 150,
              max_visits: 27,
              points_percentage_fpoints: 46_66,
              visits_percentage_fpoints: 33_33
            )
          end
        end

        context 'with a lower fixed learning evaluation' do
          before do
            create(:'course_service/fixed_learning_evaluation', course:, user_id:,
              maximal_dpoints: 200, user_dpoints: 85, visits_percentage: 25.0)
          end

          it 'sums up visits, exercises and dpoints from all sections and includes fixed evaluation' do
            expect(calculated).to have_attributes(
              visits: 9,
              main_dpoints: 50,
              main_exercises: 1,
              bonus_dpoints: 20,
              bonus_exercises: 1,
              selftest_dpoints: 30,
              selftest_exercises: 3,
              max_dpoints: 150,
              max_visits: 27,
              points_percentage_fpoints: 42_50, # The fixed evaluation is always preferred for points
              visits_percentage_fpoints: 33_33 # The greater evaluation is always preferred for visits
            )
          end
        end

        context 'with a greater fixed learning evaluation' do
          before do
            create(:'course_service/fixed_learning_evaluation', course:, user_id:,
              maximal_dpoints: 200, user_dpoints: 150, visits_percentage: 62.5)
          end

          it 'sums up visits, exercises and dpoints from all sections and includes fixed evaluation' do
            expect(calculated).to have_attributes(
              visits: 9,
              main_dpoints: 50,
              main_exercises: 1,
              bonus_dpoints: 20,
              bonus_exercises: 1,
              selftest_dpoints: 30,
              selftest_exercises: 3,
              max_dpoints: 150,
              max_visits: 27,
              points_percentage_fpoints: 75_00, # The fixed evaluation is always preferred for points
              visits_percentage_fpoints: 62_50 # The greater evaluation is always preferred for visits
            )
          end
        end
      end

      describe 'alternative section without published alternatives' do
        let(:parent_section) { create(:'course_service/section', :parent, course:) }
        let(:alternative_section) { create(:'course_service/section', :child, course:, parent: parent_section, published: false) }

        before do
          create(:'course_service/item', :homework, section: alternative_section, max_dpoints: 50)
          create(:'course_service/item', :quiz, :bonus, section: alternative_section, max_dpoints: 30)

          create(:'course_service/section_choice',
            section_id: parent_section.id,
            user_id:,
            choice_ids: [alternative_section.id])

          create(:'course_service/section_progress', section: alternative_section, user_id:,
            visits: 1,
            main_dpoints: 40,
            main_exercises: 1,
            bonus_dpoints: 0,
            bonus_exercises: 0,
            selftest_dpoints: 0,
            selftest_exercises: 0)
        end

        it 'ignores unpublished alternatives for the calculation' do
          expect(calculated).to have_attributes(
            visits: 9,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 30,
            selftest_exercises: 3,
            max_dpoints: 150,
            max_visits: 27,
            points_percentage_fpoints: 46_66,
            visits_percentage_fpoints: 33_33
          )
        end
      end

      describe 'unpublished section' do
        before do
          unpublished_section = create(:'course_service/section', course:, published: false)
          create_list(:'course_service/item', 5, section: unpublished_section)
          create(:'course_service/item', :homework, section: unpublished_section, max_dpoints: 50)
          create(:'course_service/item', :quiz, :bonus, section: unpublished_section, max_dpoints: 20)
          create_list(:'course_service/item', 2, :quiz, section: unpublished_section, max_dpoints: 10)

          create(:'course_service/section_progress', section: unpublished_section, user_id:,
            visits: 5,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 20,
            selftest_exercises: 2)
        end

        # 9 visits and 5 results from published sections.
        # Therefore, expect the same results as in the happy-path case above.
        it 'ignores unpublished sections for the calculation' do
          expect(calculated).to have_attributes(
            visits: 9,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 30,
            selftest_exercises: 3,
            max_dpoints: 150,
            max_visits: 27,
            points_percentage_fpoints: 46_66,
            visits_percentage_fpoints: 33_33
          )
        end
      end
    end
  end
end
