# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, '#lti_submission_deadline_passed?' do
  subject(:deadline_passed) { item.lti_submission_deadline_passed? }

  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:allow_access_after_deadline) { false }
  let(:provider) { create(:lti_provider, course_id: course.id, allow_access_after_deadline:) }
  let(:exercise) { create(:lti_exercise, provider:) }
  let(:submission_deadline) { 1.week.ago }
  let(:item) do
    create(
      :item,
      section:,
      content: exercise,
      submission_deadline:
    )
  end

  context 'for an LTI exercise' do
    context 'when the deadline has passed' do
      context 'and the provider allows access after the deadline' do
        let(:allow_access_after_deadline) { true }

        it { is_expected.to be true }
      end

      context 'and the provider does not allow access after the deadline' do
        it { is_expected.to be false }
      end
    end

    context 'when the deadline has not passed yet' do
      let(:submission_deadline) { 1.week.from_now }

      context 'and the provider allows access after the deadline' do
        let(:allow_access_after_deadline) { true }

        it { is_expected.to be false }
      end
    end

    context 'without a deadline' do
      let(:submission_deadline) { nil }

      context 'and the provider allows access after the deadline' do
        let(:allow_access_after_deadline) { true }

        it { is_expected.to be false }
      end
    end
  end

  context 'for an item that is no LTI exercise' do
    let(:submission_deadline) { 1.week.ago }
    let(:item) { create(:item, section:) }

    it { is_expected.to be false }
  end
end
