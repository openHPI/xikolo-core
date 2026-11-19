# frozen_string_literal: true

require 'spec_helper'

describe 'Global/Progress: Visit progress page', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:user) { create(:'account_service/user') }

  before do
    Array.new(5) do |i|
      video = create(:video)
      create(:'course_service/item',
        section:,
        title: "Video title #{i + 1}",
        content_type: 'video',
        content_id: video.id)
    end
    sign_in(user:)
    enroll_in(course)
  end

  it 'lists the section items with the first one to start with' do
    click_on('Progress')

    expect(page).to have_text 'My learning progress'

    within('details[open]', text: section.title) do
      expect(page).to have_css '[data-testid="item-card"]', count: 5
      expect(page).to have_link 'Video Video title 1 Start'
      expect(page).to have_link 'Video Video title 2', exact_text: true
    end
  end

  it 'shows the completed content in the progress header' do
    click_on('Progress')

    within('section[aria-labelledby="progress-header-title"]') do
      expect(page).to have_text 'Completed content'
      expect(page).to have_text '0 / 5'
      expect(page).to have_text '0%'
    end
  end

  it 'locks the exam section until the learner reached the required course progress' do
    exam_section = create(:'course_service/section', course:, title: 'Final exam week')
    create(:'course_service/item', :quiz, section: exam_section, title: 'Final exam', exercise_type: 'exam',
      minimum_progress_percentage: 60, content_id: create(:'quiz_service/quiz', :with_valid_question_pool).id)

    click_on('Progress')

    within('[data-testid="accordion-section"]', text: 'Final exam week') do
      expect(page).to have_text 'The exam unlocks once you have completed 60% of the course.'
      expect(page).to have_text 'The exam itself does not count towards your learning progress.'
      expect(page).to have_no_css 'details, summary, progress'
    end
  end

  it 'links from the progress header to the certificates' do
    click_on('Progress')

    expect(page).to have_link 'Download certificates', href: '#progress-certificates-title'
    expect(page).to have_css 'h2#progress-certificates-title', text: 'Certificates'
  end

  context 'without any certificates' do
    let(:course) { create(:'course_service/course', :active, cop_enabled: false, roa_enabled: false) }

    it 'does not link to the certificates' do
      click_on('Progress')

      expect(page).to have_text 'My learning progress'
      expect(page).to have_no_link 'Download certificates'
    end
  end

  it 'does not show unpublished items on progress page' do
    create(:'course_service/item',
      section:,
      title: 'Unpublished video',
      content_type: 'video',
      published: false,
      content_id: '00000003-3600-4444-9999-000000000010')

    click_on('Progress')

    within('details[open]', text: section.title) do
      expect(page).to have_css '[data-testid="item-card"]', count: 5
      expect(page).to have_no_text 'Unpublished video'
    end
  end

  context 'with quizzes' do
    before do
      completed = create(:'course_service/item', :quiz, :with_max_points, section:, title: 'Week 1 self-test')
      create(:'course_service/result', item: completed, user_id: user.id, dpoints: 10)
      create(:'course_service/item', :quiz, section:, title: 'Course feedback', exercise_type: 'survey')
    end

    it 'lists the quizzes with the learner progress on them' do
      click_on('Progress')

      within('[role="region"][aria-label="Quizzes"]') do
        expect(page).to have_css '[data-testid="item-card"]', count: 2
        expect(page).to have_link 'Self-test Week 1 self-test Completed'
        expect(page).to have_link 'Survey Course feedback'
        expect(page).to have_no_css '[aria-current="step"]'
      end
    end

    it 'locks a quiz past its submission deadline in its section and the quiz list' do
      create(:'course_service/item', :quiz, section:, title: 'Expired quiz', submission_deadline: 1.day.ago)

      click_on('Progress')

      within('details[open]', text: section.title) do
        expect(page).to have_link 'Self-test Expired quiz Locked'
      end
      within('[role="region"][aria-label="Quizzes"]') do
        expect(page).to have_link 'Self-test Expired quiz Locked'
      end
    end

    it 'shows a just failed exam to retake in its section, and as failed in the quiz list' do
      quiz = create(:'quiz_service/quiz', :with_valid_question_pool, allowed_attempts: 2)
      exam = create(:'course_service/item', :quiz, section:, title: 'Final exam', exercise_type: 'exam',
        max_dpoints: 100, content_id: quiz.id)
      create(:'course_service/visit', user:, item: exam)
      create(:'course_service/result', item: exam, user_id: user.id, dpoints: 50)
      create(:'quiz_service/quiz_submission', :submitted, quiz:, user_id: user.id)

      click_on('Progress')

      # The exam is the last visited item, but shows its outcome instead of being highlighted.
      expect(page).to have_no_css '[aria-current="step"]'
      within('details[open]', text: section.title) do
        expect(page).to have_link 'Exam Final exam Not passed Retake'
      end
      within('[role="region"][aria-label="Quizzes"]') do
        expect(page).to have_link 'Exam Final exam Not passed', exact_text: true
      end
    end

    it 'highlights the last visited quiz' do
      create(:'course_service/visit', user:, item: CourseService::Item.find_by!(title: 'Course feedback'))

      click_on('Progress')

      within('[role="region"][aria-label="Quizzes"]') do
        expect(page).to have_css 'a[aria-current="step"]', count: 1, text: 'Course feedback'
      end
    end
  end

  context 'after visiting an item' do
    let!(:next_section) { create(:'course_service/section', course:, title: 'Week 2') }

    before do
      video = create(:video)
      create(:'course_service/item', section: next_section, title: 'Week 2 video', content_type: 'video',
        content_id: video.id)
    end

    it 'continues at the last visited item' do
      click_on('Progress')
      within('details[open]', text: section.title) { click_on('Video title 2') }

      expect(page).to have_current_path(%r{/learn/#{course.course_code}/items/})

      visit course_progress_path(course_id: course.course_code)

      within('details[open]', text: section.title) do
        expect(page).to have_css '[aria-current="step"]', count: 1
        expect(page).to have_link 'Video Video title 2 Continue'
        expect(page).to have_link 'Video Video title 1', exact_text: true
      end
      expect(page).to have_css 'details:not([open])', text: 'Week 2'
    end
  end
end
