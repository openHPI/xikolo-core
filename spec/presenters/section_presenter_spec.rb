# frozen_string_literal: true

require 'spec_helper'

describe SectionPresenter, type: :presenter do
  subject(:presenter) { described_class.new(section:) }

  let(:course) { create(:'course_service/course', :active) }

  context 'with a course service record' do
    let(:section) { create(:'course_service/section', course:, start_date:, end_date:) }
    let(:start_date) { 1.day.ago }
    let(:end_date) { 1.day.from_now }

    it { is_expected.to be_available }

    context 'that has ended' do
      let(:start_date) { 2.weeks.ago }
      let(:end_date) { 1.week.ago }

      it { is_expected.not_to be_available }
    end

    context 'that has not started yet' do
      let(:start_date) { 1.day.from_now }
      let(:end_date) { 1.week.from_now }

      it { is_expected.not_to be_available }
    end

    context 'in a course that starts after the section' do
      let(:course) { create(:'course_service/course', :upcoming) }

      it 'is locked until the course starts' do
        expect(presenter).not_to be_available
        expect(presenter.effective_start_date).to be_within(1.second).of(course.start_date)
      end
    end

    context 'in a self-paced course' do
      let(:course) { create(:'course_service/course', :self_paced) }

      it 'knows the course is archived' do
        expect(presenter.course_archived).to be true
      end
    end
  end
end
