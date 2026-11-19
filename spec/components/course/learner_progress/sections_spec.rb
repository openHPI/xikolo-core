# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerProgress::Sections, type: :component do
  subject(:component) do
    described_class.new(progresses, course, current_item_id:, locked_item_ids:)
  end

  let(:current_item_id) { nil }
  let(:locked_item_ids) { [] }

  let(:course) { build(:'course_service/course', course_code: 'digital-justice') }
  let(:progresses) do
    [
      {
        'kind' => 'section', 'resource_id' => '00000002-3100-4444-9999-000000000001', 'title' => 'Week 1',
        'items' => [
          {'id' => '00000003-3100-4444-9999-000000000001', 'title' => 'Welcome video',
           'content_type' => 'video', 'user_state' => 'visited'},
          {'id' => '00000003-3100-4444-9999-000000000002', 'title' => 'Self-test 1',
           'content_type' => 'quiz', 'exercise_type' => 'selftest', 'user_state' => 'new', 'max_points' => 3.0},
        ]
      },
      {'kind' => 'section', 'resource_id' => '00000002-3100-4444-9999-000000000002', 'title' => 'Week 2',
       'items' => nil},
      {'kind' => 'course'},
    ]
  end

  it 'lists each section' do
    render_inline(component)

    expect(page).to have_css 'details summary', text: 'Week 1'
    expect(page).to have_css 'details summary', text: 'Week 2'
  end

  it 'lists the items of a section with the learner progress on them' do
    render_inline(component)

    # The sections are collapsed, which hides their items.
    section = page.find('details', text: 'Week 1')
    expect(section).to have_css '[data-testid="item-card"]', count: 2, visible: :all
    expect(section).to have_link 'Video Welcome video Completed', visible: :all
    expect(section).to have_link 'Self-test Self-test 1', exact_text: true, visible: :all
  end

  it 'explains when a section has no items' do
    render_inline(component)

    expect(page.find('details', text: 'Week 2')).to have_text :all, 'No available items'
  end

  it 'collapses all sections without a current item' do
    render_inline(component)

    expect(page).to have_no_css 'details[open]'
  end

  it 'shows the learner progress on each section' do
    render_inline(component)

    summary = page.find('details summary', text: 'Week 1')
    expect(summary).to have_text '1/2'
    expect(summary).to have_css 'progress[value="1"][max="2"]'
    expect(summary).to have_no_text 'Completed'
  end

  it 'shows no progress for a section without items' do
    render_inline(component)

    expect(page.find('details summary', text: 'Week 2')).to have_no_css 'progress'
  end

  context 'with a completed section' do
    let(:progresses) do
      super().tap {|progresses| progresses[0]['items'][1].merge!('user_state' => 'submitted', 'user_points' => 3.0) }
    end

    it 'marks it as completed' do
      render_inline(component)

      summary = page.find('details summary', text: 'Week 1')
      expect(summary).to have_text '2/2'
      expect(summary).to have_text 'Completed'
    end
  end

  context 'with an exam section' do
    let(:progresses) do
      super().tap do |progresses|
        progresses[1]['items'] = [{'id' => '00000003-3100-4444-9999-000000000003', 'title' => 'Final exam',
                                   'content_type' => 'quiz', 'exercise_type' => 'exam', 'user_state' => 'new',
                                   'max_points' => 20.0}]
      end
    end

    it 'explains that the exam does not count towards the progress' do
      render_inline(component)

      summary = page.find('details summary', text: 'Week 2')
      expect(summary).to have_text 'The exam itself does not count towards your learning progress.'
      expect(summary).to have_no_css 'progress'
      expect(summary).to have_no_text 'The exam unlocks'
    end

    context 'when the exam is locked until the learner reached the required course progress' do
      subject(:component) { described_class.new(progresses, course, exam_unlock_percentage: 70) }

      it 'locks the section, telling the course progress needed to unlock the exam' do
        render_inline(component)

        section = page.find('[data-testid="accordion-section"]', text: 'Week 2')
        expect(section).to have_no_css 'details, summary'
        expect(section).to have_text 'The exam unlocks once you have completed 70% of the course.'
        expect(section).to have_text 'The exam itself does not count towards your learning progress.'
        expect(section).to have_no_text 'This section is not available yet.'
        expect(section).to have_no_text :all, 'Final exam'
      end
    end
  end

  context 'with a section before its start date' do
    let(:progresses) do
      super().tap {|progresses| progresses[1].merge!('available' => false) }
    end

    it 'locks it, so it cannot be opened' do
      render_inline(component)

      section = page.find('[data-testid="accordion-section"]', text: 'Week 2')
      expect(section).to have_text 'This section is not available yet.'
      expect(section).to have_no_css 'details, summary, progress'
      expect(section).to have_no_text :all, 'No available items'
    end
  end

  context 'with a locked item' do
    let(:locked_item_ids) { ['00000003-3100-4444-9999-000000000002'] }

    it 'marks it as locked and still links it' do
      render_inline(component)

      expect(page.find('details', text: 'Week 1')).to have_link 'Self-test Self-test 1 Locked', visible: :all
    end
  end

  context 'with a current item' do
    let(:current_item_id) { '00000003-3100-4444-9999-000000000002' }

    it 'opens its section and highlights it' do
      render_inline(component)

      expect(page).to have_css 'details[open]', count: 1
      section = page.find('details[open]')
      expect(section).to have_css 'summary', text: 'Week 1'
      expect(section).to have_css 'a[aria-current="step"]', count: 1
      expect(section).to have_link 'Self-test Self-test 1 Start'
    end
  end

  context 'with alternative sections' do
    let(:progresses) do
      [
        {'kind' => 'section', 'title' => 'Choose a track', 'alternative_state' => 'parent'},
        {'kind' => 'section', 'title' => 'Track A', 'alternative_state' => 'child', 'items' => []},
        {'kind' => 'course'},
      ]
    end

    it 'lists the alternatives but not their parent section' do
      render_inline(component)

      expect(page).to have_css 'details summary', text: 'Track A'
      expect(page).to have_no_text 'Choose a track'
    end
  end
end
