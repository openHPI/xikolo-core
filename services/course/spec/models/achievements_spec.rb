# frozen_string_literal: true

require 'spec_helper'

describe Achievements, type: :model do
  subject(:achievements) { described_class.new(course.id, user_id) }

  let(:course) { create(:course, course_params) }
  let(:course_params) { {cop_enabled: true, roa_enabled: true, on_demand: false} }
  let(:user_id) { generate(:user_id) }
  let(:item_params) { {section: create(:section, course:)} }
  let!(:item) { create(:item, :homework, :with_max_points, item_params) }

  before { create(:enrollment, course:, user_id:) }

  describe '#cop_state' do
    subject(:state) { achievements.cop_state }

    context 'without CoP enabled' do
      let(:course_params) { {cop_enabled: false} }

      it 'is :unavailable' do
        expect(state).to eq(:unavailable)
      end
    end

    context 'with sufficient item visits for CoP' do
      before { create(:visit, item:, user_id:) }

      context 'with CoP not yet released' do
        let(:course_params) { super().merge(records_released: false) }

        it 'is :not_released' do
          expect(state).to eq(:not_released)
        end
      end

      context 'with CoP released' do
        let(:course_params) { super().merge(records_released: true) }

        it 'is :released' do
          expect(state).to eq(:released)
        end
      end
    end

    context 'without requirements for CoP fulfilled' do
      it 'is :not_achieved' do
        expect(state).to eq(:not_achieved)
      end
    end

    context 'with ended course' do
      let(:course_params) { super().merge(status: 'archive', start_date: 2.weeks.ago, end_date: 1.week.ago) }

      it { expect(state).to eq(:not_achieved) }
    end

    context 'with sufficient score for RoA' do
      before do
        create(:result, item:, user_id:, dpoints: 8)
      end

      context 'with roa released' do
        let(:course_params) { super().merge(records_released: true) }

        it 'is :achieved_via_roa' do
          expect(state).to eq(:achieved_via_roa)
        end
      end
    end
  end

  describe '#roa_state' do
    subject(:state) { achievements.roa_state }

    context 'in course without RoA' do
      let(:course_params) { {roa_enabled: false} }

      it 'is :unavailable' do
        expect(state).to eq(:unavailable)
      end
    end

    context 'with sufficient score for RoA' do
      before { create(:result, item:, user_id:, dpoints: 8) }

      context 'with records not yet released' do
        let(:course_params) { super().merge(records_released: false) }

        it 'is :not_released' do
          expect(state).to eq(:not_released)
        end
      end

      context 'with records released' do
        let(:course_params) { super().merge(records_released: true) }

        it 'is :released' do
          expect(state).to eq(:released)
        end
      end
    end

    context 'without fulfilled requirements for RoA' do
      it 'is :not_achieved' do
        expect(state).to eq(:not_achieved)
      end

      context 'after course end' do
        let(:course_params) { super().merge(status: 'archive', start_date: 2.weeks.ago, end_date: 1.week.ago) }

        it 'is :no_longer_achievable' do
          expect(state).to eq(:no_longer_achievable)
        end

        context 'with course reactivation' do
          let(:course_params) { super().merge(on_demand: true) }

          it 'is :reactivatable' do
            expect(state).to eq(:reactivatable)
          end
        end
      end

      context 'in course running forever' do
        let(:course_params) { super().merge(status: 'active', start_date: 2.weeks.ago, end_date: nil) }
        let(:item_params) { super().merge(submission_deadline: nil) }

        it 'is :not_achieved' do
          expect(state).to eq(:not_achieved)
        end
      end
    end
  end
end
