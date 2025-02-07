# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerDashboard::SectionProgress::Item, type: :component do
  let(:course) { create(:course) }
  let(:section_progress) do
    build(:'course:section_progress', 'items' => [item])
  end
  let(:item) do
    {
      'id' => '19b3bc6b-f2f7-4a52-aab5-e0ce75d78b3f',
      'title' => 'Graded quiz',
      'content_type' => 'quiz',
      'exercise_type' => 'main',
      'user_state' => 'visited',
      'optional' => false,
      'max_points' => 10.0,
      'user_points' => nil,
      'time_effort' => nil,
      'open_mode' => false,
    }
  end
  let(:component) do
    described_class.new(section_progress['items'].first, course)
  end

  shared_examples 'a quiz or peer assessment' do
    it 'shows the correct icon for quizzes or peer assessments' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
    end
  end

  shared_examples 'an optional quiz' do
    it 'shows the correct icon for optional quizzes' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Optional quiz']")
      expect(page).to have_css("[data-tooltip='Optional quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
    end
  end

  shared_examples 'an LTI exercise' do
    it 'shows the correct icon for LTI exercises' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-display-code')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
    end
  end

  shared_examples 'a survey' do
    it 'shows the correct icon for surveys' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Survey']")
      expect(page).to have_css("[data-tooltip='Survey']")
      expect(page).to have_css('.fa-clipboard-list-check')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
    end
  end

  shared_examples 'a video' do
    it 'shows the correct icon for videos' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Video item']")
      expect(page).to have_css("[data-tooltip='Video item']")
      expect(page).to have_css('.fa-video')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
    end
  end

  shared_examples 'an item with status: no progress' do
    it 'shows the item without coloured status' do
      render_inline(component)

      expect(page).to have_css('.section-progress__material-item')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  shared_examples 'an item with status: critical' do
    it 'shows the item, indicating that the quiz result is critical' do
      render_inline(component)

      expect(page).to have_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  shared_examples 'an item with status: warning' do
    it 'shows the item, indicating that the quiz result can be improved' do
      render_inline(component)

      expect(page).to have_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  shared_examples 'an item with status: completed' do
    it 'shows the item as completed' do
      render_inline(component)

      expect(page).to have_css('.section-progress__material-item--completed')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
    end
  end

  context 'for a quiz' do
    context 'with zero available points' do
      let(:item) { super().merge('max_points' => 0.0) }

      context 'that has not been submitted' do
        it_behaves_like 'a quiz or peer assessment'
        it_behaves_like 'an item with status: no progress'
      end

      context 'that has been submitted' do
        let(:item) { super().merge('user_state' => 'submitted') }

        it_behaves_like 'a quiz or peer assessment'
        it_behaves_like 'an item with status: completed'
      end
    end

    context 'that has not yet been visited' do
      let(:item) { super().merge('user_state' => 'new') }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: no progress'
    end

    context 'with less than 50% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 3.0) }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: critical'
    end

    context 'with exactly or more than 50% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 5.0) }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: warning'
    end

    context 'with more than 95% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 9.6) }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: completed'

      it 'does not shows the item as optional' do
        render_inline(component)

        expect(page).to have_no_css('.section-progress__material-item--optional')
      end
    end

    context 'which is optional has achieved points > 95%' do
      let(:item) { super().merge('title' => 'Optional quiz', 'optional' => true, 'user_state' => 'graded', 'user_points' => 9.6) }

      it_behaves_like 'an optional quiz'
      it_behaves_like 'an item with status: completed'

      it 'shows the item as optional' do
        render_inline(component)

        expect(page).to have_css('.section-progress__material-item--optional')
      end
    end
  end

  context 'for an LTI exercise' do
    let(:item) { super().merge('content_type' => 'lti_exercise') }

    context 'that has not yet been visited' do
      let(:item) { super().merge('user_state' => 'new') }

      it_behaves_like 'an LTI exercise'
      it_behaves_like 'an item with status: no progress'
    end

    context 'with less than 50% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 3.0) }

      it_behaves_like 'an LTI exercise'
      it_behaves_like 'an item with status: critical'
    end

    context 'with exactly or more than 50% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 5.0) }

      it_behaves_like 'an LTI exercise'
      it_behaves_like 'an item with status: warning'
    end

    context 'with more than 95% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 9.6) }

      it_behaves_like 'an LTI exercise'
      it_behaves_like 'an item with status: completed'
    end
  end

  context 'for a peer assessment exercise' do
    let(:item) { super().merge('content_type' => 'peer_assessment') }

    context 'that has not yet been visited' do
      let(:item) { super().merge('user_state' => 'new') }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: no progress'
    end

    context 'with less than 50% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 3.0) }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: critical'
    end

    context 'with exactly or more than 50% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 5.0) }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: warning'
    end

    context 'with more than 95% achieved points' do
      let(:item) { super().merge('user_state' => 'graded', 'user_points' => 9.6) }

      it_behaves_like 'a quiz or peer assessment'
      it_behaves_like 'an item with status: completed'
    end
  end

  context 'for a survey' do
    let(:item) { super().merge('title' => 'Survey', 'exercise_type' => 'survey') }

    context 'that has been visited but not completed' do
      let(:item) { super().merge('user_state' => 'visited') }

      it_behaves_like 'a survey'
      it_behaves_like 'an item with status: no progress'
    end

    context 'that has been visited and completed (submitted)' do
      let(:item) { super().merge('user_state' => 'submitted') }

      it_behaves_like 'a survey'
      it_behaves_like 'an item with status: completed'
    end

    context 'that has been visited and completed (graded)' do
      let(:item) { super().merge('user_state' => 'graded') }

      it_behaves_like 'a survey'
      it_behaves_like 'an item with status: completed'
    end
  end

  context 'for a video' do
    let(:item) { super().merge('title' => 'Video item', 'content_type' => 'video', 'exercise_type' => nil, 'max_points' => 0) }

    context 'that is not yet visited' do
      let(:item) { super().merge('user_state' => 'new') }

      it_behaves_like 'a video'
      it_behaves_like 'an item with status: no progress'
    end

    context 'that has been visited' do
      let(:item) { super().merge('user_state' => 'visited') }

      it_behaves_like 'a video'
      it_behaves_like 'an item with status: completed'
    end
  end
end
