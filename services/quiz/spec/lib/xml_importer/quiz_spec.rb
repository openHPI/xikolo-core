# frozen_string_literal: true

require 'spec_helper'

describe XmlImporter::Quiz do
  subject(:create_quizzes) { described_class.new(course_code, course_id, xml).create_quizzes! }

  let(:course_code) { 'a4h1' }
  let(:course_id) { '00000000-0000-4444-9999-000000000000' }
  let(:section_id) { '00000000-0000-4444-9999-000000000001' }

  before do
    Stub.service(:course, build(:'course:root'))
  end

  context 'with valid xml' do
    let(:item_result) { [] }
    let(:second_item_result) { [] }

    before do
      Stub.request(
        :course, :get, '/sections',
        query: {course_id:}
      ).to_return Stub.json(section_result)
      Stub.request(
        :course, :get, '/items',
        query: hash_including(content_id: anything)
      ).to_return Stub.json([])
      Stub.request(
        :course, :post, '/items',
        body: hash_including(content_id: anything, section_id: anything)
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/items',
        query: hash_including(section_id:)
      ).to_return Stub.json(item_result)
    end

    context 'without external references' do
      let(:xml) do
        <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <quizzes>
            <quiz bonus="false" course_code="a4h1" graded="false" published="false"
                  section="1" show_in_nav="true" skip_intro="false" survey="false">
              <name lang="en">Selftest 3.1</name>
              <instructions></instructions>
              <attempts>0</attempts>
              <time_limit>0</time_limit>
              <due_date>2014-09-10T20:00:00</due_date>
              <publish_results_date>2014-09-10T20:00:00</publish_results_date>
              <questions>
                <question points="3" shuffle_answers="true" type="MultipleAnswer">
                  <text lang="en">Which of the following statements about Company X’s user interface technology are true? Note: There are 2 correct answers to this question.</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">Increasingly, Company X is decoupling the UI from back-end systems.</text>
                      <explanation></explanation>
                    </answer>
                    <answer correct="false" type="TextAnswer">
                      <text lang="en">It offers UI and business logic in one stack.</text>
                      <explanation></explanation>
                    </answer>
                  </answers>
                </question>
                <question points="3" shuffle_answers="true" type="MultipleAnswer">
                  <text lang="en">Which 3 terms describe Company X’s UX strategy?</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">New, renew, enable</text>
                      <explanation></explanation>
                    </answer>
                  </answers>
                </question>
              </questions>
            </quiz>
          </quizzes>
        XML
      end

      let(:section_result) { [{id: section_id}] }

      it 'creates one quiz' do
        expect { create_quizzes }.to change(Quiz, :count).from(0).to(1)
      end

      it 'creates two questions' do
        expect { create_quizzes }.to change(Question, :count).from(0).to(2)
      end

      it 'creates three answers' do
        expect { create_quizzes }.to change(Answer, :count).from(0).to(3)
      end

      it 'does not raise parameter error' do
        expect { create_quizzes }.not_to raise_error
      end

      it 'stores a fallback text to avoid empty quiz instructions' do
        create_quizzes
        expect(Quiz.first.instructions).to eq 'INSERT INSTRUCTION HERE'
      end

      context 'with not matching course code' do
        let(:course_code) { 'a5h2' }

        it 'raises parameter error' do
          expect { create_quizzes }.to raise_error(XmlImporter::ParameterError)
        end
      end

      context 'with not existing section' do
        let(:xml) do
          <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <quizzes>
              <quiz bonus="false" course_code="a4h1" graded="false" published="false"
                    section="3" show_in_nav="true" skip_intro="false" survey="false">
                <name lang="en">Selftest 3.1</name>
                <instructions></instructions>
                <attempts>0</attempts>
                <time_limit>0</time_limit>
                <due_date>2014-09-10T20:00:00</due_date>
                <publish_results_date>2014-09-10T20:00:00</publish_results_date>
                <questions>
                  <question points="3" shuffle_answers="true" type="MultipleAnswer">
                    <text lang="en">Which of the following statements about Company X’s user interface technology are true? Note: There are 2 correct answers to this question.</text>
                    <answers>
                      <answer correct="true" type="TextAnswer">
                        <text lang="en">Increasingly, Company X is decoupling the UI from back-end systems.</text>
                        <explanation></explanation>
                      </answer>
                      <answer correct="false" type="TextAnswer">
                        <text lang="en">It offers UI and business logic in one stack.</text>
                        <explanation></explanation>
                      </answer>
                    </answers>
                  </question>
                  <question points="3" shuffle_answers="true" type="MultipleAnswer">
                    <text lang="en">Which 3 terms describe Company X’s UX strategy?</text>
                    <answers>
                      <answer correct="true" type="TextAnswer">
                        <text lang="en">New, renew, enable</text>
                        <explanation></explanation>
                      </answer>
                    </answers>
                  </question>
                </questions>
              </quiz>
            </quizzes>
          XML
        end

        it 'raises parameter error' do
          expect { create_quizzes }.to raise_error(XmlImporter::ParameterError)
        end
      end

      context 'with alternative section' do
        let(:second_section_id) { '00000000-0000-4444-9999-000000000002' }
        let(:alternative_section_id) { '00000000-0000-4444-9999-000000000003' }
        let(:section_result) { [{id: section_id}, {id: second_section_id}] }

        let(:xml) do
          <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <quizzes>
              <quiz bonus="false" course_code="a4h1" graded="false" published="false"
                    section="2" subsection="1" show_in_nav="true" skip_intro="false" survey="false">
                <name lang="en">Selftest 3.1</name>
                <instructions></instructions>
                <attempts>0</attempts>
                <time_limit>0</time_limit>
                <due_date>2014-09-10T20:00:00</due_date>
                <publish_results_date>2014-09-10T20:00:00</publish_results_date>
                <questions>
                  <question points="3" shuffle_answers="true" type="MultipleAnswer">
                    <text lang="en">Which of the following statements about Company X’s user interface technology are true? Note: There are 2 correct answers to this question.</text>
                    <answers>
                      <answer correct="true" type="TextAnswer">
                        <text lang="en">Increasingly, Company X is decoupling the UI from back-end systems.</text>
                        <explanation></explanation>
                      </answer>
                      <answer correct="false" type="TextAnswer">
                        <text lang="en">It offers UI and business logic in one stack.</text>
                        <explanation></explanation>
                      </answer>
                    </answers>
                  </question>
                  <question points="3" shuffle_answers="true" type="MultipleAnswer">
                    <text lang="en">Which 3 terms describe Company X’s UX strategy?</text>
                    <answers>
                      <answer correct="true" type="TextAnswer">
                        <text lang="en">New, renew, enable</text>
                        <explanation></explanation>
                      </answer>
                    </answers>
                  </question>
                </questions>
              </quiz>
            </quizzes>
          XML
        end

        let(:alternative_section_result) { [{id: alternative_section_id}] }

        before do
          Stub.request(
            :course, :get, '/items',
            query: hash_including(section_id: second_section_id)
          ).to_return Stub.json(second_item_result)
          Stub.request(
            :course, :get, '/sections',
            query: {course_id:, parent_id: second_section_id}
          ).to_return Stub.json(alternative_section_result)
        end

        it 'creates the new quiz in the alternative section' do
          expect { create_quizzes }.to change(Quiz, :count).from(0).to(1)
          expect(a_request(:post, 'http://course.xikolo.tld/items')
            .with(body: hash_including(
              content_id: anything,
              section_id: alternative_section_id,
              content_type: 'quiz',
              exercise_type: 'selftest',
              title: 'Selftest 3.1',
              published: 'false',
              show_in_nav: 'true'
            ))).to have_been_made
        end

        it 'creates two questions' do
          expect { create_quizzes }.to change(Question, :count).from(0).to(2)
        end

        it 'creates three answers' do
          expect { create_quizzes }.to change(Answer, :count).from(0).to(3)
        end

        it 'does not raise parameter error' do
          expect { create_quizzes }.not_to raise_error
        end
      end
    end

    context 'with external references' do
      let(:xml) do
        <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <quizzes>
            <quiz bonus="false" course_code="a4h1" graded="false" published="false" section="1"
                  show_in_nav="true" skip_intro="false" external_ref="#{quiz_1_ref}" survey="false">
              <name lang="en">Selftest 3.1</name>
              <instructions></instructions>
              <attempts>0</attempts>
              <time_limit>0</time_limit>
              <due_date>2014-09-10T20:00:00</due_date>
              <publish_results_date>2014-09-10T20:00:00</publish_results_date>
              <questions>
                <question points="3" shuffle_answers="true" type="MultipleAnswer">
                  <text lang="en">Which of the following statements about Company X’s user interface technology are true? Note: There are 2 correct answers to this question.</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">Increasingly, Company X is decoupling the UI from back-end systems.</text>
                      <explanation></explanation>
                    </answer>
                    <answer correct="false" type="TextAnswer">
                      <text lang="en">It offers UI and business logic in one stack.</text>
                      <explanation></explanation>
                    </answer>
                  </answers>
                </question>
                <question points="3" shuffle_answers="true" type="MultipleAnswer">
                  <text lang="en">Which 3 terms describe Company X’s UX strategy?</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">New, renew, enable</text>
                      <explanation></explanation>
                    </answer>
                  </answers>
                </question>
              </questions>
            </quiz>
            <quiz bonus="false" course_code="a4h1" graded="false" published="false" section="1"
                  show_in_nav="true" skip_intro="false" external_ref="#{quiz_2_ref}"  survey="false">
              <name lang="en">Selftest 3.2</name>
              <instructions></instructions>
              <attempts>0</attempts>
              <time_limit>0</time_limit>
              <due_date>2014-09-10T20:00:00</due_date>
              <publish_results_date>2014-09-10T20:00:00</publish_results_date>
              <questions>
                <question points="3" shuffle_answers="true" type="MultipleAnswer">
                  <text lang="en">Which of the following statements about Company Y’s user interface technology are true? Note: There are 2 correct answers to this question.</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">Increasingly, Company Y is decoupling the UI from back-end systems.</text>
                      <explanation></explanation>
                    </answer>
                    <answer correct="false" type="TextAnswer">
                      <text lang="en">It offers UI and business logic in one stack.</text>
                      <explanation></explanation>
                    </answer>
                  </answers>
                </question>
                <question points="3" shuffle_answers="true" type="MultipleAnswer">
                  <text lang="en">Which 3 terms describe Company Y’s UX strategy?</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">New, renew, enable</text>
                      <explanation></explanation>
                    </answer>
                  </answers>
                </question>
              </questions>
            </quiz>
          </quizzes>
        XML
      end
      let(:quiz_1_ref) { 'quiz 1 reference' }
      let(:quiz_2_ref) { 'quiz 2 reference' }
      let(:section_result) { [{id: section_id}] }

      context 'with one existing & one new quiz' do
        let(:quiz) { create(:quiz, external_ref_id: quiz_1_ref) }
        let(:question_1) do
          create(
            :multiple_answer_question,
            quiz:,
            text: 'Which of the following statements about Company X’s user interface technology are true? \
            Note: There are 2 correct answers to this question.'
          )
        end
        let(:question_2) do
          create(
            :multiple_answer_question,
            quiz:,
            text: 'Which 3 terms describe Company X’s UX strategy?'
          )
        end
        let(:item_result) { [{id: '20000000-0000-4444-9999-000000000000', content_id: quiz.id}] }

        before do
          create(:answer, question: question_1)
          create(:answer, question: question_1)
          create(:answer, question: question_2)
          create(:answer, question: question_2)
        end

        it 'creates one quiz' do
          expect { create_quizzes }.to change(Quiz, :count).from(1).to(2)
        end

        it 'creates the correct quiz' do
          create_quizzes
          expect(Quiz.find_by(external_ref_id: quiz_2_ref)).to be_truthy
        end

        it 'creates two questions' do
          expect { create_quizzes }.to change(Question, :count).from(2).to(4)
        end

        it 'creates three answers' do
          expect { create_quizzes }.to change(Answer, :count).from(4).to(7)
        end

        it 'does not raise parameter error' do
          expect { create_quizzes }.not_to raise_error
        end

        it 'stores a fallback text to avoid empty quiz instructions' do
          create_quizzes
          expect(Quiz.find_by(external_ref_id: quiz_2_ref).instructions).to eq 'INSERT INSTRUCTION HERE'
        end
      end

      context 'with not matching course code' do
        let(:course_code) { 'a5h2' }

        it 'raises parameter error' do
          expect { create_quizzes }.to raise_error(XmlImporter::ParameterError)
        end
      end

      context 'with an existing quiz with the same external_ref_id in the same course' do
        let(:quiz) { create(:quiz, external_ref_id: quiz_1_ref) }
        let(:quiz_2_ref) { quiz_1_ref }
        let(:item_result) { [{id: '20000000-0000-4444-9999-000000000000', content_id: quiz.id}] }

        it 'does not create a new quiz' do
          expect { create_quizzes }.not_to change(Quiz, :count).from(1)
        end
      end

      context 'with an existing quiz with the same external_ref_id in a another course' do
        # The course service does not return this quiz' id as an item's
        # content_id in a section of the current course.
        let(:quiz) { create(:quiz, external_ref_id: quiz_1_ref) }

        it 'creates both quizzes' do
          quiz
          expect { create_quizzes }.to change(Quiz, :count).from(1).to(3)
        end
      end
    end
  end

  context 'with invalid XML' do
    let(:xml) do
      <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <quizzes>
          </quiz>
        </quizzes>
      XML
    end

    it 'raises schema error' do
      expect { create_quizzes }.to raise_error(XmlImporter::SchemaError)
    end
  end
end
