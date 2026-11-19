# frozen_string_literal: true

require 'spec_helper'

describe Course::CertificatesPresenter do
  subject(:presenter) { described_class.new(course_id: course.id, user_id: learner.id, current_user:) }

  let(:course) { create(:course, records_released: true, cop_threshold_percentage: 50, roa_threshold_percentage: 50) }
  let(:learner) { create(:'account_service/user') }
  let(:current_user) do
    CurrentUser::User.new(session: create(:'account_service/session', user: learner), context_id: 'root')
  end
  let(:evaluation) { :with_evaluation } # 50% visited, 80% of points
  let(:cop) { card(Certificate::Record::COP) }
  let(:roa) { card(Certificate::Record::ROA) }

  before do
    create(:'course_service/enrollment', evaluation, course:, user: learner)
    create(:certificate_template, :cop, course:)
    create(:certificate_template, :roa, course:)
  end

  def card(type)
    presenter.cards.find {|c| c.type == type }
  end

  describe '#cards' do
    it 'returns a card per enabled certificate' do
      expect(presenter.cards.map(&:type)).to eq [Certificate::Record::COP, Certificate::Record::ROA]
    end

    context 'with only the confirmation of participation enabled' do
      let(:course) { create(:course, records_released: true, roa_enabled: false) }

      it 'returns a single card' do
        expect(presenter.cards.map(&:type)).to eq [Certificate::Record::COP]
      end
    end

    context 'without any certificate enabled' do
      let(:course) { create(:course, cop_enabled: false, roa_enabled: false) }

      it { is_expected.not_to be_any }
    end
  end

  describe '#unlock_status' do
    it 'returns all_unlocked when all enabled certificates are achieved' do
      expect(presenter.unlock_status).to eq :all_unlocked
    end

    context 'without achieved certificates' do
      let(:evaluation) { :with_low_evaluation }

      it { expect(presenter.unlock_status).to eq :none_unlocked }
    end

    context 'with only some certificates achieved' do
      let(:course) { create(:course, cop_threshold_percentage: 50, roa_threshold_percentage: 90) }

      it { expect(presenter.unlock_status).to eq :partially_unlocked }
    end

    context 'with a single enabled certificate' do
      let(:course) { create(:course, cop_threshold_percentage: 50, roa_enabled: false) }

      it { expect(presenter.unlock_status).to eq :all_unlocked }
    end

    context 'before certificates are released' do
      let(:course) { create(:course, records_released: false, cop_threshold_percentage: 50, roa_threshold_percentage: 50) }

      it { expect(presenter.unlock_status).to eq :all_unlocked }
    end
  end

  describe '#mascot_message' do
    it 'celebrates when all enabled certificates are earned' do
      expect(presenter.mascot_message).to eq 'Everything unlocked. Nice work!'
    end

    context 'when no certificate is earned and participation is still achievable' do
      let(:evaluation) { :with_low_evaluation }
      let(:course) { create(:course, on_demand: false, start_date: 4.weeks.ago, end_date: 1.week.ago) }

      it { expect(presenter.mascot_message).to eq "Nothing unlocked yet? You've got this!" }
    end

    context 'when only participation is earned and another certificate remains achievable' do
      let(:course) { create(:course, cop_threshold_percentage: 50, roa_threshold_percentage: 90) }

      it { expect(presenter.mascot_message).to eq 'Your first certificates are here. Keep it up!' }
    end

    context 'when no further certificate is achievable' do
      let(:course) do
        create(:course, on_demand: false, start_date: 4.weeks.ago, end_date: 1.week.ago,
          cop_threshold_percentage: 50, roa_threshold_percentage: 90)
      end

      it 'has no message when only participation is earned' do
        expect(presenter.mascot_message).to be_nil
      end

      context 'with participation disabled and nothing earned' do
        before { course.update!(cop_enabled: false) }

        it { expect(presenter.mascot_message).to be_nil }
      end
    end
  end

  describe 'card' do
    it 'shows the requirement' do
      expect(roa.requirement).to eq 'Achieve an overall score of 50%.'
    end

    context 'with achieved certificates' do
      it 'is achieved and downloadable' do
        expect(cop).to be_achieved
        expect(cop.download_path).to eq "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation"
      end

      it 'is not issued until the first download' do
        expect(cop.issued_on).to eq 'Not downloaded yet'
      end

      it 'shows the issue date once the record exists' do
        create(:cop, course:, user: learner, template: Certificate::Template.find_by(course:, certificate_type: 'ConfirmationOfParticipation'))

        expect(cop.issued_on).to eq I18n.l(Time.zone.today)
      end
    end

    context 'with the confirmation of participation achieved via the record of achievement' do
      let(:course) { create(:course, records_released: true, cop_threshold_percentage: 60, roa_threshold_percentage: 50) }

      it 'counts as achieved and is downloadable' do
        expect(cop).to be_achieved
        expect(cop.download_path).to be_present
      end
    end

    context 'when not achieved' do
      let(:evaluation) { :with_low_evaluation } # 25% visited, 45% of points

      it 'is pending without a date or download' do
        expect(roa).not_to be_achieved
        expect(roa.issued_on).to eq '—'
        expect(roa.download_path).to be_nil
      end
    end

    context 'when records are not released' do
      let(:course) { create(:course, records_released: false) }

      it 'is achieved but not available yet' do
        expect(roa).to be_achieved
        expect(roa.issued_on).to eq 'Not available yet'
        expect(roa.download_path).to be_nil
      end
    end

    context 'without a template' do
      before { Certificate::Template.where(course:, certificate_type: 'RecordOfAchievement').delete_all }

      it 'is not downloadable' do
        expect(roa.download_path).to be_nil
      end
    end

    context 'when a teacher views the learner progress' do
      let(:current_user) { CurrentUser::User.new(session: create(:'account_service/session'), context_id: 'root') }

      it 'is not downloadable' do
        expect(roa).to be_achieved
        expect(roa.download_path).to be_nil
      end
    end

    context 'when the course has an exam' do
      let(:exam_section) { create(:'course_service/section', course:) }
      let(:exam_quiz) { create(:'quiz_service/quiz', :with_valid_question_pool) }
      let(:exam) do
        create(:'course_service/item', :quiz, exercise_type: 'exam',
          section: exam_section, content_id: exam_quiz.id)
      end

      before { exam }

      def create_exam_submission(question_points:, submission_points:)
        question = create(:'quiz_service/multiple_choice_question', quiz: exam_quiz, points: question_points)
        create(:'quiz_service/quiz_submission', quiz: exam_quiz, user: learner,
          quiz_submission_time: 1.hour.ago).tap do |submission|
          create(:'quiz_service/quiz_submission_question',
            quiz_submission: submission, quiz_question_id: question.id, points: submission_points)
        end
      end

      context 'with no passing exam attempt' do
        it 'shows exam-specific description and requirement' do
          expect(roa.description).to eq 'You have not yet passed the final exam of this course.'
          expect(roa.requirement).to eq 'Achieve at least 70% in the final exam.'
        end
      end

      context 'with a passing exam attempt (not yet released)' do
        let(:course) { create(:course, records_released: false) }

        before { create_exam_submission(question_points: 10, submission_points: 7) }

        it 'is achieved but not released' do
          expect(roa).to be_achieved
          expect(roa.requirement).to eq 'Achieve at least 70% in the final exam.'
        end
      end

      context 'with a passing exam attempt (released)' do
        before { create_exam_submission(question_points: 10, submission_points: 7) }

        it 'shows exam-specific description and requirement' do
          expect(roa.description).to eq 'Congratulations! You achieved the openHPI certificate for this course.'
          expect(roa.requirement).to eq 'Achieve at least 70% in the final exam.'
        end
      end
    end
  end
end
