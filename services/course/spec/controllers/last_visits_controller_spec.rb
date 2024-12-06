# frozen_string_literal: true

require 'spec_helper'

describe LastVisitsController, type: :controller do
  subject { action; response }

  let(:json) { JSON.parse response.body }

  let!(:course) { create(:course) }
  let(:user_id) { generate(:user_id) }

  let(:section1) { create(:section, course:, position: 1, start_date: 10.days.ago.iso8601) }
  let(:item11) { create(:item, section: section1, position: 1) }
  let(:item12) { create(:item, section: section1, position: 2) }

  describe '#show' do
    context 'without user' do
      let(:action) { get :show, params: {course_id: course.id} }

      its(:status) { is_expected.to eq 404 }
    end

    context 'without enrollment' do
      let(:action) { get :show, params: {course_id: course.id, user_id:} }

      its(:status) { is_expected.to eq 404 }
    end

    context 'with enrollment' do
      let(:action) { get :show, params: {course_id: course.id, user_id:} }

      before { create(:enrollment, user_id:, course:) }

      its(:status) { is_expected.to eq 200 }

      context 'without item visits' do
        context 'json' do
          subject { action; json }

          let(:expected_value) { {item_id: nil, visit_date: nil} }

          it { is_expected.to eq(expected_value.stringify_keys) }
        end
      end

      context 'with consecutive item visits' do
        let(:visit11_date) { 2.days.ago.iso8601 }
        let(:visit12_date) { 1.day.ago.iso8601 }

        before do
          item11; item12
          create(:visit, item: item11, user_id:, updated_at: visit11_date)
          create(:visit, item: item12, user_id:, updated_at: visit12_date)
        end

        context 'json' do
          subject { action; json }

          let(:expected_value) { {item_id: item12.id, visit_date: visit12_date} }

          it { is_expected.to eq(expected_value.stringify_keys) }
        end
      end

      context 'with repeated item visits' do
        let(:visit12_date) { 1.day.ago.iso8601 }
        let(:visit12_date_update) { 6.hours.ago.iso8601 }

        before do
          item12
          visit12 = create(:visit, item: item12, user_id:, updated_at: visit12_date)
          visit12.updated_at = visit12_date_update
          visit12.save
        end

        context 'json' do
          subject { action; json }

          let(:expected_value) { {item_id: item12.id, visit_date: visit12_date_update} }

          it { is_expected.to eq(expected_value.stringify_keys) }
        end
      end
    end
  end
end
