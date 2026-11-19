# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Edit a quiz', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:quiz) { create(:'quiz_service/quiz', instructions: 'This is a instruction text') }
  let(:question) do
    create(:'quiz_service/multiple_answer_question',
      quiz:,
      text: 'What is the Internet?',
      points: 3,
      shuffle_answers: false)
  end
  let!(:answer_1) do
    create(:'quiz_service/text_answer',
      question:,
      correct: true,
      text: 'The Internet is a global system of interconnected computer networks that use the standard Internet protocol suite (TCP/IP) to serve several billion users worldwide.',
      position: 1)
  end
  let!(:answer_2) do
    create(:'quiz_service/text_answer',
      question:,
      correct: false,
      text: 'The Internet consists of cookies.',
      position: 2)
  end
  let(:item) do
    create(:'course_service/item',
      section:,
      title: 'An Example Item',
      content_type: 'quiz',
      content_id: quiz.id,
      exercise_type:,
      max_dpoints: 30,
      published:)
  end
  let(:exercise_type) { 'selftest' }
  let(:published) { false }

  before do
    item

    user = create(:'account_service/user')
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)
    sign_in(user:)

    visit "/learn/#{course.course_code}"

    click_on 'Course Administration'
    expect(page).to have_text('Welcome, teacher!') # Assert the teacher menu is open to reduce flakiness
    click_on 'Structure & Content'

    within("[data-id=\"#{section.id}\"]") do
      # Click on the edit pen. Needs to be made accessible!
      find('a .fa-pen-to-square').click
    end
  end

  it 'switches question type' do
    click_on 'Questions'

    within '.quiz-question-editor__header' do
      find("[aria-label='More actions']").click
    end
    within "[data-behaviour='menu-dropdown']" do
      click_on 'Edit question'
    end

    select 'Single Select', from: 'Type'
    click_on 'Submit Question'

    click_on 'Questions'

    within '.quiz-question-editor' do
      expect(page).to have_text('Question 1')
      expect(page).to have_text('Single Select Question')
    end
  end

  it 'creates a new question with question type' do
    click_on 'Questions'

    select 'Single Select', from: 'Question type'
    fill_markdown_editor('Question text', with: 'What is the capital of France?')
    fill_in('Points', with: 5)
    click_on 'Create Question'

    click_on 'Add answer'
    expect(page).to have_text('Answer text')
    fill_markdown_editor('Answer text', with: 'Paris')
    check 'Answer is correct', allow_label_click: true
    click_on 'Create Answer'

    expect(page).to have_text('What is the capital of France?')
  end

  it 'does not offer the question pool for non-exams' do
    click_on 'Quiz settings'

    expect(page).to have_no_field('Question Pool')
  end

  context 'for exams' do
    let(:exercise_type) { 'exam' }
    # An exam is always backed by a question-pool quiz (item validation requires it).
    let(:quiz) do
      create(:'quiz_service/quiz',
        instructions: 'This is a instruction text',
        question_pool: true,
        displayed_question_count: 10)
    end

    it 'fixes the question pool settings' do
      click_on 'Quiz settings'

      expect(page).to have_field('Questions shown to each learner')
      expect(page).to have_unchecked_field('xikolo_course_item_published', visible: :all)
      expect(page).to have_no_field('Unlimited attempts')
      expect(page).to have_no_field('Allowed attempts')
      click_button 'Save item'

      expect(page).to have_text('The exam remains unpublished')
      expect(item.reload.published).to be(false)

      click_on 'Quiz settings'
      expect(quiz.reload.question_pool).to be(true)
    end

    context 'with question pool enabled' do
      before do
        click_on 'Quiz settings'
        click_button 'Save item'
        expect(page).to have_text('The item was updated successfully.')
      end

      it 'sets points when selecting Easy difficulty' do
        click_on 'Questions'

        within '.quiz-question-editor__header' do
          find("[aria-label='More actions']").click
        end
        within "[data-behaviour='menu-dropdown']" do
          click_on 'Edit question'
        end

        select('Easy', from: 'Difficulty')
        click_on 'Submit Question'

        expect(page).to have_text('1.0 Points')
        expect(question.reload.points).to eq(1)
      end

      it 'sets points when selecting Mid difficulty' do
        click_on 'Questions'

        within '.quiz-question-editor__header' do
          find("[aria-label='More actions']").click
        end
        within "[data-behaviour='menu-dropdown']" do
          click_on 'Edit question'
        end

        select('Mid', from: 'Difficulty')
        click_on 'Submit Question'

        expect(page).to have_text('2.0 Points')
        expect(question.reload.points).to eq(2.0)
      end

      it 'sets points when selecting Hard difficulty' do
        click_on 'Questions'

        within '.quiz-question-editor__header' do
          find("[aria-label='More actions']").click
        end
        within "[data-behaviour='menu-dropdown']" do
          click_on 'Edit question'
        end

        select('Hard', from: 'Difficulty')
        click_on 'Submit Question'

        expect(page).to have_text('3.0 Points')
        expect(question.reload.points).to eq(3.0)
      end

      it 'unsets difficulty when selecting Not defined' do
        # First set a difficulty
        click_on 'Questions'

        within '.quiz-question-editor__header' do
          find("[aria-label='More actions']").click
        end
        within "[data-behaviour='menu-dropdown']" do
          click_on 'Edit question'
        end

        select('Easy', from: 'Difficulty')
        click_on 'Submit Question'
        expect(page).to have_text('1.0 Points')
        expect(question.reload.points).to eq(1.0)

        # Then switch to Not defined
        click_on 'Questions'

        within '.quiz-question-editor__header' do
          find("[aria-label='More actions']").click
        end
        within "[data-behaviour='menu-dropdown']" do
          click_on 'Edit question'
        end

        select('Not defined', from: 'Difficulty')
        fill_in('Points', with: 5)
        click_on 'Submit Question'

        expect(page).to have_no_text('Difficulty')
        expect(question.reload.points).to eq(5.0)
      end
    end

    context 'with a published, valid question pool' do
      let(:published) { true }
      let(:quiz) do
        create(:'quiz_service/quiz', :with_valid_question_pool)
      end
      let(:question) { quiz.questions.first }

      it 'saves the published question pool' do
        click_on 'Quiz settings'

        expect(page).to have_checked_field('xikolo_course_item_published', visible: :all)
        wait_for_turbo_idle
        click_button 'Save item'

        expect(page).to have_text 'The item was updated successfully.'
        expect(item.reload.published).to be(true)
      end
    end
  end

  it 'switches question type with too many correct answers' do
    answer_2.update!(correct: true)

    click_on 'Questions'

    within '.quiz-question-editor__header' do
      find("[aria-label='More actions']").click
    end
    within "[data-behaviour='menu-dropdown']" do
      click_on 'Edit question'
    end

    select 'Single Select', from: 'Type'
    click_on 'Submit Question'

    click_on 'Questions'

    within '.quiz-question-editor' do
      expect(page).to have_text('Question 1')
      expect(page).to have_text('Single Select Question')
    end

    expect(page).to have_text(
      'Single Select Questions should only have 1 correct answer! Please review the question.'
    )
  end

  it 'adds a new answer' do
    click_on 'Questions'

    click_on 'Add answer'
    fill_markdown_editor('Answer text', with: 'Newly added answer')
    click_on 'Create Answer'

    expect(page).to have_text 'Newly added answer'
  end

  it 'edits an answer' do
    click_on 'Questions'

    within "[data-id='#{answer_1.id}']" do
      find("[aria-label='More actions']").click
      click_on 'Edit'
    end

    fill_markdown_editor('Answer text', with: 'New answer text')
    click_on 'Update Answer'

    expect(page).to have_text 'New answer text'
  end

  it 'deletes a quiz question' do
    click_on 'Questions'

    within "[data-id='#{question.id}'] .quiz-question-editor__header" do
      find("[aria-label='More actions']").click
      within "[data-behaviour='menu-dropdown']" do
        click_on 'Delete question'
      end
    end

    expect(page).to have_text 'Are you sure you want to delete this question?'
    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    click_on 'Questions'
    expect(page).to have_text(/Question\(s\):\s+0/)
  end

  it 'deletes an answer' do
    click_on 'Questions'

    within "[data-id='#{answer_1.id}']" do
      find("[aria-label='More actions']").click
      click_on 'Delete'
    end

    expect(page).to have_text 'Are you sure you want to delete this answer?'
    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    click_on 'Questions'

    expect(page).to have_no_text answer_1.text
  end
end
