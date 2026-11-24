# frozen_string_literal: true

require 'spec_helper'

describe Course::QuizListPresenter, type: :presenter do
  subject(:presenter) { described_class.new(course, user_id, progresses) }

  let(:course) { create(:'course_service/course', course_code: 'digital-justice') }
  let(:user_id) { create(:'account_service/user').id }
  let(:week1) { create(:'course_service/section', course:, title: 'Week 1', position: 1) }
  let(:week2) { create(:'course_service/section', course:, title: 'Week 2', position: 2) }
  let(:week3) { create(:'course_service/section', course:, title: 'Week 3', position: 3, start_date: 1.week.from_now) }
  let(:draft) { create(:'course_service/section', course:, title: 'Draft', position: 4, published: false) }
  let(:progresses) do
    [week1, week2, week3, draft].map {|section| {'kind' => 'section', 'resource_id' => section.id} } +
      [{'kind' => 'course'}]
  end
  let(:quizzes) { presenter.to_a }

  before do
    self_test = create(:'course_service/item', :quiz, :with_max_points, section: week1, title: 'Self-test 1')
    create(:'course_service/result', item: self_test, user_id:, dpoints: 10)
    create(:'course_service/item', section: week1, title: 'Intro video')
    create(:'course_service/item', :quiz, section: week1, title: 'Closed quiz', end_date: 1.day.ago)
    create(:'course_service/item', :quiz, section: week1, title: 'Unpublished quiz', published: false)
    create(:'course_service/item', :quiz, section: week1, title: 'Upcoming quiz', start_date: 1.day.from_now)
    create(:'course_service/item', :quiz, section: week2, title: 'Final exam', exercise_type: 'exam',
      content: create(:'quiz_service/quiz', :with_valid_question_pool))
    create(:'course_service/item', :quiz, section: week2, title: 'Survey', exercise_type: 'survey')
    create(:'course_service/item', :quiz, section: week3, title: 'Next week quiz')
    create(:'course_service/item', :quiz, section: draft, title: 'Draft section quiz')
  end

  it 'lists the published quizzes, including upcoming and closed ones, in course order' do
    expect(quizzes.map(&:title)).to eq ['Self-test 1', 'Closed quiz', 'Upcoming quiz', 'Final exam', 'Survey', 'Next week quiz']
  end

  it 'marks completed quizzes and locks closed and upcoming quizzes and exams' do
    expect(quizzes.map(&:state)).to eq %i[completed locked locked locked default locked]
  end

  it 'lists the ids of the locked quizzes' do
    expect(presenter.locked_item_ids).to match_array CourseService::Item
      .where(title: ['Closed quiz', 'Upcoming quiz', 'Final exam', 'Next week quiz']).ids
  end

  context 'when a section has ended' do
    before { week2.update!(end_date: 1.day.ago) }

    it 'locks an unfinished quiz in that section' do
      survey = quizzes.find {|quiz| quiz.title == 'Survey' }

      expect(survey.state).to eq :locked
    end
  end

  context 'when the submission deadline of a quiz has passed' do
    before do
      create(:'course_service/item', :quiz, section: week2, title: 'Expired quiz', submission_deadline: 1.day.ago)
    end

    let(:expired_quiz) { quizzes.find {|quiz| quiz.title == 'Expired quiz' } }

    it 'locks the quiz, but links its page about the passed deadline' do
      expect(expired_quiz.state).to eq :locked
      expect(expired_quiz.path).to start_with '/learn/digital-justice/items/'
    end

    context 'when the learner reactivated the course' do
      before { create(:'course_service/enrollment', :reactivated, course:, user_id:) }

      it 'keeps the quiz unlocked until the forced submission date' do
        expect(expired_quiz.state).to eq :default
      end
    end

    context 'when the reactivation has expired' do
      before { create(:'course_service/enrollment', :was_reactivated, course:, user_id:) }

      it 'locks the quiz' do
        expect(expired_quiz.state).to eq :locked
      end
    end
  end

  context 'with the current item' do
    subject(:presenter) { described_class.new(course, user_id, progresses, current_item_id:) }

    let(:current_item_id) { CourseService::Item.find_by!(title: 'Self-test 1').id }

    it 'highlights it, even though completed' do
      expect(quizzes.map(&:state)).to eq %i[current locked locked locked default locked]
    end
  end

  it 'links locked exams, as their page explains the required course progress' do
    exam = quizzes.find {|quiz| quiz.title == 'Final exam' }

    expect(exam.state).to eq :locked
    expect(exam.path).to start_with '/learn/digital-justice/items/'
  end

  it 'tells the course progress the learner needs to unlock the exam' do
    expect(presenter.exam_unlock_percentage).to eq 75
  end

  context 'with a required course progress configured for the exam' do
    before { CourseService::Item.find_by!(title: 'Final exam').update!(minimum_progress_percentage: 70) }

    it 'tells that course progress' do
      expect(presenter.exam_unlock_percentage).to eq 70
    end
  end

  context 'when the learner reached the required course progress' do
    before do
      create(:'course_service/course_progress', course:, user_id:, visits_percentage_fpoints: 8_000)
    end

    it 'unlocks the exam' do
      expect(quizzes.map(&:state)).to eq %i[completed locked locked default default locked]
      expect(presenter.exam_unlock_percentage).to be_nil
    end
  end

  context 'with an exam graded below its pass percentage' do
    let(:exam_item) { CourseService::Item.find_by!(title: 'Final exam') }
    let(:exam_quiz) { QuizService::Quiz.find(exam_item.content_id) }
    let(:exam) { quizzes.find {|quiz| quiz.title == 'Final exam' } }

    before do
      exam_item.update!(max_dpoints: 100)
      create(:'course_service/result', item: exam_item, user_id:, dpoints: 50)
      create(:'quiz_service/quiz_submission', :submitted, quiz: exam_quiz, user_id:)
    end

    it 'marks it as failed' do
      expect(exam.state).to eq :failed
    end

    context 'when current' do
      subject(:presenter) { described_class.new(course, user_id, progresses, current_item_id: exam_item.id) }

      it 'shows it as failed rather than as the current item' do
        expect(exam.state).to eq :failed
      end
    end

    it 'cannot be retaken without attempts left' do
      expect(presenter.retakable_item_ids).to eq []
    end

    context 'with attempts left' do
      before { exam_quiz.update!(allowed_attempts: 2) }

      it 'can be retaken' do
        expect(presenter.retakable_item_ids).to eq [exam_item.id]
      end

      context 'once its submission deadline passed' do
        before { exam_item.update!(submission_deadline: 1.day.ago) }

        it 'stays failed, but cannot be retaken' do
          expect(exam.state).to eq :failed
          expect(presenter.retakable_item_ids).to eq []
        end
      end
    end

    context 'with an additional attempt granted' do
      before { create(:'quiz_service/additional_quiz_attempt', quiz_id: exam_quiz.id, user_id:, count: 1) }

      it 'can be retaken' do
        expect(presenter.retakable_item_ids).to eq [exam_item.id]
      end
    end
  end

  context 'without quizzes' do
    subject(:presenter) { described_class.new(create(:'course_service/course'), user_id, []) }

    it { is_expected.not_to be_any }
  end
end
