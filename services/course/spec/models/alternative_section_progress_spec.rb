# frozen_string_literal: true

require 'spec_helper'

describe AlternativeSectionProgress, type: :model do
  subject(:alternative_progress) { described_class.new(parent: parent_section, user: user_id) }

  let(:user_id) { generate(:user_id) }
  let!(:parent_section) { create(:section, :parent) }
  let!(:alternative_section1) { create(:section, :child, parent: parent_section) }
  let!(:alternative_section2) { create(:section, :child, parent: parent_section) }
  let(:progress1) { create(:section_progress, section: alternative_section1, user_id:) }
  let(:progress2) { create(:section_progress, section: alternative_section2, user_id:) }

  describe '#set_best_alternative!' do
    subject(:set_alternative) { alternative_progress.set_best_alternative! }

    describe '(points)' do
      before do
        create(:item, :homework, section: alternative_section1, max_dpoints: 50)
        create(:item, :quiz, :bonus, section: alternative_section1, max_dpoints: 30)
        create(:item, :homework, section: alternative_section2, max_dpoints: 60)
        create(:item, :quiz, :bonus, section: alternative_section2, max_dpoints: 40)
      end

      context 'without any results' do
        before do
          progress1
          progress2
        end

        it 'correctly determines the best alternative with the least max points' do
          # Alternative 1: user_dpoints: 0, max_dpoints: 50
          # Alternative 2: user_dpoints: 0, max_dpoints: 60
          expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect { set_alternative }.not_to change { progress2.reload.alternative_progress_for }
        end

        context 'with (now) outdated best alternative' do
          before do
            progress2.update_column(:alternative_progress_for, parent_section.id)
          end

          it 'correctly determines the best alternative with the least max points' do
            expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
              .from(nil).to(parent_section.id)
          end

          it 'resets the outdated best alternative' do
            expect { set_alternative }.to change { progress2.reload.alternative_progress_for }
              .from(parent_section.id).to(nil)
          end
        end
      end

      context 'with incomplete results and no bonus points' do
        before do
          progress1.update visits: 1, main_dpoints: 50
          progress2.update visits: 1, main_dpoints: 50
        end

        it 'correctly determines the best alternative with the highest graded percentage' do
          # Alternative 1: user_dpoints: 50, max_dpoints: 50, visits: 1 / 4
          # Alternative 2: user_dpoints: 50, max_dpoints: 60, visits: 1 / 4
          expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect { set_alternative }.not_to change { progress2.reload.alternative_progress_for }
        end
      end

      context 'with complete results but no bonus points' do
        before do
          progress1.update visits: 1, main_dpoints: 50
          progress2.update visits: 1, main_dpoints: 60
        end

        it 'correctly determines the best alternative with the highest max points' do
          # Alternative 1: user_dpoints: 50, max_dpoints: 50, visits: 1 / 4
          # Alternative 2: user_dpoints: 60, max_dpoints: 60, visits: 1 / 4
          expect(progress2.points_percentage).to eq 100
          expect(progress2.section.goals(user_id).max_dpoints).to eq 60
          expect { set_alternative }.to change { progress2.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect(progress1.points_percentage).to eq 100
          expect(progress1.section.goals(user_id).max_dpoints).to eq 50
          expect { set_alternative }.not_to change { progress1.reload.alternative_progress_for }
        end
      end

      context 'with incomplete results and bonus points in one alternative section' do
        before do
          progress1.update visits: 2, main_dpoints: 20, bonus_dpoints: 30
          progress2.update visits: 1, main_dpoints: 50
        end

        it 'correctly determines the best alternative with the highest graded percentage' do
          # Alternative 1: user_dpoints: 50, max_dpoints: 50, visits: 2 / 4
          # Alternative 2: user_dpoints: 50, max_dpoints: 60, visits: 1 / 4
          expect(progress1.points_percentage).to eq 100
          expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect { set_alternative }.not_to change { progress2.reload.alternative_progress_for }
        end
      end

      context 'with complete results and bonus points in one alternative section' do
        before do
          progress1.update visits: 2, main_dpoints: 50, bonus_dpoints: 30
          progress2.update visits: 1, main_dpoints: 50
        end

        it 'correctly determines the best alternative with the highest graded percentage' do
          # Alternative 1: user_dpoints: 80, max_dpoints: 50, visits: 2 / 4
          # Alternative 2: user_dpoints: 50, max_dpoints: 60, visits: 1 / 4
          expect(progress1.points_percentage).to eq 100
          expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect { set_alternative }.not_to change { progress2.reload.alternative_progress_for }
        end
      end

      context 'with complete results and bonus points' do
        before do
          progress1.update visits: 2, main_dpoints: 50, bonus_dpoints: 30
          progress2.update visits: 2, main_dpoints: 60, bonus_dpoints: 40
        end

        it 'correctly determines the best alternative with the highest max points' do
          # Alternative 1: user_dpoints: 80, max_dpoints: 50, visits: 2 / 4
          # Alternative 2: user_dpoints: 100, max_dpoints: 60, visits: 2 / 4
          expect(progress2.points_percentage).to eq 100
          expect(progress2.section.goals(user_id).max_dpoints).to eq 60
          expect { set_alternative }.to change { progress2.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect(progress1.points_percentage).to eq 100
          expect(progress1.section.goals(user_id).max_dpoints).to eq 50
          expect { set_alternative }.not_to change { progress1.reload.alternative_progress_for }
        end
      end
    end

    describe '(visits)' do
      before do
        create(:item, section: alternative_section1)
        create(:item, section: alternative_section1)
        create(:item, section: alternative_section2)
        create(:item, section: alternative_section2)
        create(:item, section: alternative_section2)
        create(:item, section: alternative_section2)
      end

      context 'without any visits' do
        before do
          progress1
          progress2
        end

        it 'correctly determines the best alternative with the least visits' do
          # Alternative 1: visits: 0 / 2
          # Alternative 2: visits: 0 / 4
          expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect { set_alternative }.not_to change { progress2.reload.alternative_progress_for }
        end
      end

      context 'with different visit percentages' do
        context 'and the first alternative section has the most visits' do
          before do
            progress1.update visits: 2
            progress2.update visits: 1
          end

          it 'correctly determines the best alternative with the most visits' do
            # Alternative 1: visits: 2 / 2
            # Alternative 2: visits: 1 / 4
            expect { set_alternative }.to change { progress1.reload.alternative_progress_for }
              .from(nil).to(parent_section.id)
          end

          it 'does not update other alternatives' do
            expect { set_alternative }.not_to change { progress2.reload.alternative_progress_for }
          end
        end

        context 'and the second alternative section has the most visits' do
          before do
            progress1.update visits: 1
            progress2.update visits: 3
          end

          it 'correctly determines the best alternative with the most visits' do
            # Alternative 1: visits: 1 / 2
            # Alternative 2: visits: 3 / 4
            expect { set_alternative }.to change { progress2.reload.alternative_progress_for }
              .from(nil).to(parent_section.id)
          end

          it 'does not update other alternatives' do
            expect { set_alternative }.not_to change { progress1.reload.alternative_progress_for }
          end
        end
      end

      context 'with equal visit percentage' do
        before do
          progress1.update visits: 1
          progress2.update visits: 2
        end

        it 'correctly determines the best alternative with the most visits' do
          # Alternative 1: visits: 1 / 2
          # Alternative 2: visits: 2 / 4
          expect(progress2.visits_percentage).to eq 50
          expect { set_alternative }.to change { progress2.reload.alternative_progress_for }
            .from(nil).to(parent_section.id)
        end

        it 'does not update other alternatives' do
          expect(progress1.visits_percentage).to eq 50
          expect { set_alternative }.not_to change { progress1.reload.alternative_progress_for }
        end
      end
    end
  end
end
