# frozen_string_literal: true

require 'spec_helper'

describe Gamification::DashboardPresenter, type: :presenter do
  subject(:presenter) { described_class.new(user) }

  let(:user) { create(:user) }

  describe '#badges' do
    subject(:badges) { presenter.badges }

    context 'without badges' do
      it 'returns three ungained badges' do
        expect(badges).to contain_exactly(an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: false), an_object_having_attributes(name: 'knowledgeable', level: 0, persisted?: false), an_object_having_attributes(name: 'communicator', level: 0, persisted?: false))
      end
    end

    context 'with badges for different users' do
      before { create(:gamification_badge, :gold, name: 'selftest_master') }

      it 'returns three ungained badges' do
        expect(badges).to contain_exactly(an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: false), an_object_having_attributes(name: 'knowledgeable', level: 0, persisted?: false), an_object_having_attributes(name: 'communicator', level: 0, persisted?: false))
      end
    end

    context 'with a single selftest_master badge' do
      before { create(:gamification_badge, :gold, name: 'selftest_master', user:) }

      it 'returns three badges, one of them a gained selftest_master badge' do
        expect(badges).to contain_exactly(an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: true), an_object_having_attributes(name: 'knowledgeable', level: 0, persisted?: false), an_object_having_attributes(name: 'communicator', level: 0, persisted?: false))
      end
    end

    context 'with multiple global badges' do
      before do
        create(:gamification_badge, :bronze, name: 'communicator', user:)
        create(:gamification_badge, :silver, name: 'communicator', user:)
        create(:gamification_badge, :bronze, name: 'knowledgeable', user:)
        create(:gamification_badge, :silver, name: 'knowledgeable', user:)
        create(:gamification_badge, :gold, name: 'knowledgeable', user:)
      end

      it 'returns three badges, using only the highest level per badge' do
        expect(badges).to contain_exactly(an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: false), an_object_having_attributes(name: 'knowledgeable', level: 2, persisted?: true), an_object_having_attributes(name: 'communicator', level: 1, persisted?: true))
      end
    end

    context 'with multiple course-specific badges for different course' do
      before do
        create(:gamification_badge, :gold, name: 'selftest_master', user:, course_id: generate(:course_id))
        create(:gamification_badge, :gold, name: 'selftest_master', user:, course_id: generate(:course_id))
        create(:gamification_badge, :gold, name: 'selftest_master', user:, course_id: generate(:course_id))
      end

      it 'returns five badges, with multiple instances of the course-specific one' do
        expect(badges).to contain_exactly(an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: true), an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: true), an_object_having_attributes(name: 'selftest_master', level: 2, persisted?: true), an_object_having_attributes(name: 'knowledgeable', level: 0, persisted?: false), an_object_having_attributes(name: 'communicator', level: 0, persisted?: false))
      end
    end
  end

  describe '#scores' do
    subject(:scores) { presenter.scores }

    let(:course1) { create(:course, :archived, title: 'Course 1') }
    let(:course2) { create(:course, :archived, title: 'Course 2') }

    it 'determines what columns to display' do
      expect(scores.columns).to eq %i[selftests communication total]
    end

    context 'without scores' do
      it 'returns no scores' do
        expect(scores.any?).to be false
      end
    end

    context 'with scores' do
      before do
        create_list(:gamification_score, 3, :answer_create, points: 1, user:, course: course1)
        create_list(:gamification_score, 2, :accepted_answer, points: 5, user:, course: course2)
        create_list(:gamification_score, 2, :selftest_master, points: 10, user:, course: course2)
      end

      it 'consists of course-specific and then total scores' do
        expect(scores.any?).to be true
        expect(scores.by_course).to eq({
          course1 => {selftests: 0, communication: 3, total: 3},
          course2 => {selftests: 20, communication: 10, total: 30},
          'Total' => {selftests: 20, communication: 13, total: 33},
        })
      end

      context 'with scores in missing course' do
        let(:course2) { create(:course, :archived, :deleted) }

        it 'ignores the scores for the missing course' do
          expect(scores.any?).to be true
          expect(scores.by_course).to eq({
            course1 => {selftests: 0, communication: 3, total: 3},
            '(Course not available)' => {selftests: 20, communication: 10, total: 30},
            'Total' => {selftests: 20, communication: 13, total: 33},
          })
        end
      end

      context 'with scores in categories not displayed' do
        before do
          create(:gamification_score, :continuous_attendance, points: 1, user:, course: course1)
          create(:gamification_score, :continuous_attendance, points: 1, user:,
            course: create(:course, :archived, title: 'Course 3'))
        end

        it 'ignores scores from those categories' do
          expect(scores.any?).to be true
          expect(scores.by_course).to eq({
            course1 => {selftests: 0, communication: 3, total: 3},
            course2 => {selftests: 20, communication: 10, total: 30},
            'Total' => {selftests: 20, communication: 13, total: 33},
          })
        end
      end

      context 'with a course without scores' do
        before do
          create(:course, :archived, title: 'Course 3')
        end

        it 'does not list such a course' do
          expect(scores.any?).to be true
          expect(scores.by_course).to eq({
            course1 => {selftests: 0, communication: 3, total: 3},
            course2 => {selftests: 20, communication: 10, total: 30},
            'Total' => {selftests: 20, communication: 13, total: 33},
          })
        end
      end

      context 'with a course having only scores of 0 points' do
        before do
          # Scores with zero points may be stored in order to track the
          # completion of a larger goal (in this case: selftest master).
          # The learner will only get points once the larger goal is achieved.
          create(:gamification_score, :take_selftest, points: 0, user:,
            course: create(:course, :archived, title: 'Course 3'))
        end

        it 'does not list such a course' do
          expect(scores.any?).to be true
          expect(scores.by_course).to eq({
            course1 => {selftests: 0, communication: 3, total: 3},
            course2 => {selftests: 20, communication: 10, total: 30},
            'Total' => {selftests: 20, communication: 13, total: 33},
          })
        end
      end
    end
  end
end
