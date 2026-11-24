# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::Persister do
  describe '#create_quiz!' do
    let(:sections) { instance_double(ActiveRecord::Relation) }
    let(:course) { instance_double(CourseService::Course, sections:) }
    let(:quiz_obj) do
      instance_double(
        QuizImporter::Quiz,
        name: 'Quiz 1',
        section: 99,
        subsection: nil,
        survey: false,
        bonus: false,
        graded: true,
        final_exam: false,
        instructions: 'x',
        time: 10,
        attempts: 1,
        external_ref: nil
      )
    end
    let(:created_quiz) { instance_double(QuizService::Quiz, id: 123) }
    let(:persister) { described_class.new(course, []) }

    before do
      allow(ActiveRecord::Base).to receive(:transaction).and_yield
      allow(QuizService::Quiz).to receive(:create!).and_return(created_quiz)
      allow(sections).to receive(:order).with(:position).and_return([])
    end

    it 'raises when the configured section does not exist' do
      expect { persister.send(:create_quiz!, quiz_obj) }
        .to raise_error(QuizImporter::ProcessWorksheetError, "Section #{quiz_obj.section} not found for quiz #{quiz_obj.name}")
    end
  end

  describe '#create_item!' do
    subject(:create_item!) { persister.send(:create_item!, quiz_obj, quiz.id, section) }

    let(:course) { instance_double(CourseService::Course) }
    let(:persister) { described_class.new(course, []) }
    let(:quiz) { instance_double(QuizService::Quiz, id: 123) }
    let(:section) { instance_double(CourseService::Section, id: 5) }
    let(:quiz_obj) do
      instance_double(
        QuizImporter::Quiz,
        name: 'Exam',
        survey: false,
        bonus: false,
        graded: true,
        final_exam: true
      )
    end

    it 'creates the quiz item' do
      created_item = instance_double(CourseService::Item)
      allow(CourseService::Item).to receive(:create!).and_return(created_item)

      expect { create_item! }.not_to raise_error
      expect(CourseService::Item).to have_received(:create!).once
    end

    context 'when the item fails a validation (e.g. an exam already exists)' do
      let(:record) do
        item = CourseService::Item.new(exercise_type: 'exam', content: build(:'quiz_service/quiz'))
        item.errors.add(:exercise_type, :exam_already_exists)
        item
      end

      before do
        allow(CourseService::Item).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(record))
      end

      it 'raises a ProcessWorksheetError with the validation message' do
        expect { create_item! }
          .to raise_error(QuizImporter::ProcessWorksheetError, /#{I18n.t('errors.messages.exam_already_exists')}/)
      end
    end
  end

  describe '#persist!' do
    subject(:persist!) { persister.persist! }

    let(:course) { instance_double(CourseService::Course) }
    let(:answer) { instance_double(QuizImporter::Answer) }
    let(:question) { instance_double(QuizImporter::Question, answers: [answer]) }
    let(:quiz) { instance_double(QuizImporter::Quiz, questions: [question]) }
    let(:quizzes) { [quiz] }
    let(:persisted_question) { Struct.new(:id).new(42) }
    let(:persister) { described_class.new(course, quizzes) }

    before do
      allow(persister).to receive(:create_quiz!).with(quiz).and_yield(11)
      allow(persister).to receive(:create_question!).with(question, 11).and_return(persisted_question)
      allow(persister).to receive(:create_answer!).with(answer, 42)
      allow(persister).to receive(:update_item_max_points).with(11)
    end

    it 'creates quizzes, questions, answers and updates max points' do
      persist!

      expect(persister).to have_received(:create_quiz!).with(quiz)
      expect(persister).to have_received(:create_question!).with(question, 11)
      expect(persister).to have_received(:create_answer!).with(answer, 42)
      expect(persister).to have_received(:update_item_max_points).with(11)
    end

    context 'with multiple quizzes' do
      let(:quiz) { instance_double(QuizImporter::Quiz, questions: []) }
      let(:quiz2) { instance_double(QuizImporter::Quiz, questions: []) }
      let(:quizzes) { [quiz, quiz2] }

      before do
        allow(persister).to receive(:create_quiz!).with(quiz).and_yield(1)
        allow(persister).to receive(:create_quiz!).with(quiz2).and_yield(2)
        allow(persister).to receive(:update_item_max_points).with(1)
        allow(persister).to receive(:update_item_max_points).with(2)
      end

      it 'persists each quiz' do
        persist!

        expect(persister).to have_received(:create_quiz!).with(quiz)
        expect(persister).to have_received(:create_quiz!).with(quiz2)
        expect(persister).to have_received(:update_item_max_points).with(1)
        expect(persister).to have_received(:update_item_max_points).with(2)
      end
    end

    context 'with no quizzes' do
      let(:quizzes) { [] }

      it 'does not create anything' do
        persist!

        expect(persister).not_to have_received(:create_quiz!)
      end
    end

    context 'when quiz has nil questions' do
      let(:quiz) { instance_double(QuizImporter::Quiz, questions: nil) }

      before do
        allow(persister).to receive(:create_quiz!).with(quiz).and_yield(7)
        allow(persister).to receive(:update_item_max_points).with(7)
      end

      it 'skips question and answer creation' do
        persist!

        expect(persister).to have_received(:create_quiz!).with(quiz)
        expect(persister).not_to have_received(:create_question!)
        expect(persister).not_to have_received(:create_answer!)
      end
    end

    context 'when question has nil answers' do
      let(:question) { instance_double(QuizImporter::Question, answers: nil) }
      let(:quiz) { instance_double(QuizImporter::Quiz, questions: [question]) }

      it 'creates question but skips answers' do
        persist!

        expect(persister).to have_received(:create_question!).with(question, 11)
        expect(persister).not_to have_received(:create_answer!)
      end
    end

    it 'bubbles up errors from quiz creation' do
      allow(persister).to receive(:create_quiz!).with(quiz).and_raise(StandardError, 'boom')

      expect { persist! }.to raise_error(StandardError, 'boom')
    end
  end
end
