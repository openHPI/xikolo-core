# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Processors::QuizProcessor, type: :model do
  let(:content_type) { 'quiz' }
  let(:item) { create(:item, content_type:) }
  let(:processor) { described_class.new item }
  let(:quiz_instruction) { 'Some instructions' }
  let(:question_markup) { 'Some question?' }
  let(:answer_markup) { 'Some answer!' }

  describe '#initialize' do
    it 'initializes the course_item correctly' do
      expect(processor.course_item).to be_nil
    end

    it 'initializes the quiz correctly' do
      expect(processor.quiz).to be_nil
    end

    it 'initializes the questions correctly' do
      expect(processor.questions).to be_nil
    end
  end

  describe '#load_resources!' do
    subject(:load_resources) { processor.load_resources! }

    let(:question_id) { SecureRandom.uuid }
    let(:course_item_stub) do
      Stub.request(:course, :get, "/items/#{item.id}")
        .to_return Stub.json({id: item.id})
    end
    let(:quiz_stub) do
      Stub.request(:quiz, :get, "/quizzes/#{item.content_id}")
        .to_return Stub.json({
          id: item.content_id,
          instructions: quiz_instruction,
        })
    end
    let(:questions_stub) do
      Stub.request(:quiz, :get, '/questions', query: {quiz_id: item.content_id})
        .to_return Stub.json([{
          id: question_id,
          text: question_markup,
        }])
    end
    let(:answers_stub) do
      Stub.request(:quiz, :get, '/answers', query: {question_id:})
        .to_return Stub.json([{
          text: answer_markup,
        }])
    end

    before do
      Stub.service(:course, item_url: 'http://course.xikolo.tld/items/{id}')
      Stub.service(:quiz,
        quiz_url: 'http://quiz.xikolo.tld/quizzes/{id}',
        questions_url: 'http://quiz.xikolo.tld/questions',
        answers_url: 'http://quiz.xikolo.tld/answers')
      course_item_stub
      quiz_stub
      questions_stub
      answers_stub
    end

    context 'w/ valid content type' do
      it 'requests the course item' do
        load_resources
        expect(course_item_stub).to have_been_requested
        expect(processor.course_item['id']).to eq item.id
      end

      it 'requests the quiz' do
        load_resources
        expect(quiz_stub).to have_been_requested
        expect(processor.quiz['id']).to eq item.content_id
      end

      it 'requests the quiz questions' do
        load_resources
        expect(questions_stub).to have_been_requested
        expect(processor.questions.size).to eq 1
        expect(processor.questions.first['id']).to eq question_id
      end

      it 'requests the quiz answers' do
        load_resources
        expect(answers_stub).to have_been_requested
        expect(processor.questions.first['answers'].size).to eq 1
        expect(processor.questions.first['answers'].first['text']).to eq answer_markup
      end

      context 'without any question' do
        let(:questions_stub) do
          Stub.request(:quiz, :get, '/questions', query: {quiz_id: item.content_id})
            .to_return Stub.json([])
        end

        it 'requests the quiz questions' do
          load_resources
          expect(questions_stub).to have_been_requested
          expect(processor.questions.size).to eq 0
        end
      end
    end

    context 'w/o valid content type' do
      let(:content_type) { 'rich_text' }

      it 'raises an error' do
        expect { load_resources }.to raise_error Errors::InvalidItemType
        expect(course_item_stub).not_to have_been_requested
      end
    end

    context 'w/ error while loading quiz' do
      let(:course_item_stub) do
        Stub.request(:course, :get, "/items/#{item.id}")
          .to_return Stub.response(status: 404)
      end

      it 'raises an error' do
        expect { load_resources }.to raise_error Errors::LoadResourcesError
        expect(course_item_stub).to have_been_requested
        expect(quiz_stub).not_to have_been_requested
      end
    end
  end

  describe '#calculate' do
    subject(:calculate_time_effort) { processor.calculate }

    context 'w/ all required resources loaded' do
      let(:course_item) { {'exercise_type' => exercise_type} }
      let(:quiz) { {'instructions' => quiz_instruction} }
      let(:question) do
        {
          'text' => question_markup,
        }
      end
      let(:rich_text_handler) { instance_double(ItemTypes::RichText) }
      let(:quiz_handler) { instance_double(ItemTypes::Quiz) }
      let(:exercise_type) { 'main' }

      before do
        processor.instance_variable_set(:@course_item, course_item)
        processor.instance_variable_set(:@quiz, quiz)
        processor.instance_variable_set(:@questions, [question])
      end

      # We're stubbing out all the logic that estimates the time effort for
      # various parts of taking the quiz.
      # All we're testing here is that these factors are weighted correctly
      # according to the type of quiz.
      context 'w/ main exercise' do
        it 'sets the time effort correctly' do
          allow(processor).to receive_messages(approximate_reading_time: 20.5, quiz_taking_time: 20)
          calculate_time_effort
          expect(processor.time_effort).to eq 81
        end
      end

      context 'w/ selftest' do
        let(:exercise_type) { 'selftest' }

        it 'sets the time effort correctly' do
          allow(processor).to receive_messages(approximate_reading_time: 20.5, quiz_taking_time: 20)
          calculate_time_effort
          expect(processor.time_effort).to eq 41
        end
      end
    end

    context 'w/o all required resources loaded' do
      it 'does not set time effort' do
        expect { calculate_time_effort }.not_to change(processor, :time_effort)
      end
    end
  end
end
