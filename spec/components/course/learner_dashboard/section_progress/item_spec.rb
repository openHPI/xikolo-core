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

  context 'for a quiz or exercise that has not yet been visited' do
    let(:item) { super().merge('user_state' => 'new') }

    it 'shows the item as not yet visited' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a quiz or exercise with less than 50% achieved points' do
    let(:item) { super().merge('user_state' => 'graded', 'user_points' => 3.0) }

    it 'shows the item, indicating that the quiz result is critical' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a quiz or exercise with exactly or more than 50% achieved points' do
    let(:item) { super().merge('user_state' => 'graded', 'user_points' => 5.0) }

    it 'shows the item, indicating that the quiz result can be improved' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a quiz or exercise with more than 95% achieved points' do
    let(:item) { super().merge('user_state' => 'graded', 'user_points' => 9.6) }

    it 'shows the item as completed' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--completed')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--optional')
    end
  end

  context 'for an optional quiz with more than 95% achieved points' do
    let(:item) { super().merge('title' => 'Optional quiz', 'optional' => true, 'user_state' => 'graded', 'user_points' => 9.6) }

    it 'shows the item as completed while indicating that it is optional' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Optional quiz']")
      expect(page).to have_css("[data-tooltip='Optional quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--completed')
      expect(page).to have_css('.section-progress__material-item--optional')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
    end
  end

  context 'for an LTI exercise that has not yet been visited' do
    let(:item) { super().merge('user_state' => 'new', 'content_type' => 'lti_exercise') }

    it 'shows the item as not yet visited' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-display-code')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for an LTI exercise with less than 50% achieved points' do
    let(:item) { super().merge('content_type' => 'lti_exercise', 'user_state' => 'graded', 'user_points' => 3.0) }

    it 'shows the item, indicating that the quiz result is critical' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-display-code')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a LTI exercise with exactly or more than 50% achieved points' do
    let(:item) { super().merge('content_type' => 'lti_exercise', 'user_state' => 'graded', 'user_points' => 5.0) }

    it 'shows the item, indicating that the quiz result can be improved' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-display-code')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a LTI exercise with more than 95% achieved points' do
    let(:item) { super().merge('content_type' => 'lti_exercise', 'user_state' => 'graded', 'user_points' => 9.6) }

    it 'shows the item as completed' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-display-code')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--completed')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
    end
  end

  context 'for a peer assessment exercise that has not yet been visited' do
    let(:item) { super().merge('user_state' => 'new', 'content_type' => 'peer_assessment') }

    it 'shows the item as not yet visited' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a peer assessment exercise with less than 50% achieved points' do
    let(:item) { super().merge('content_type' => 'peer_assessment', 'user_state' => 'graded', 'user_points' => 3.0) }

    it 'shows the item, indicating that the quiz result is critical' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a peer assessment exercise with exactly or more than 50% achieved points' do
    let(:item) { super().merge('content_type' => 'peer_assessment', 'user_state' => 'graded', 'user_points' => 5.0) }

    it 'shows the item, indicating that the quiz result can be improved' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--warning')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--completed')
    end
  end

  context 'for a peer assessment exercise with more than 95% achieved points' do
    let(:item) { super().merge('content_type' => 'peer_assessment', 'user_state' => 'graded', 'user_points' => 9.6) }

    it 'shows the item as completed' do
      render_inline(component)

      expect(page).to have_css("[aria-label='Graded quiz']")
      expect(page).to have_css("[data-tooltip='Graded quiz']")
      expect(page).to have_css('.fa-money-check-pen')
      expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
      expect(page).to have_css('.section-progress__material-item--completed')
      expect(page).to have_no_css('.section-progress__material-item--critical')
      expect(page).to have_no_css('.section-progress__material-item--warning')
    end
  end

  context 'for a survey' do
    context 'that has been visited but not completed' do
      let(:item) { super().merge('title' => 'Survey', 'exercise_type' => 'survey', 'user_state' => 'visited') }

      it 'shows the item as gray' do
        render_inline(component)

        expect(page).to have_css("[aria-label='Survey']")
        expect(page).to have_css("[data-tooltip='Survey']")
        expect(page).to have_css('.fa-clipboard-list-check')
        expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
        expect(page).to have_no_css('.section-progress__material-item--completed')
        expect(page).to have_no_css('.section-progress__material-item--critical')
        expect(page).to have_no_css('.section-progress__material-item--warning')
      end
    end

    context 'that has been visited and completed (submitted)' do
      let(:item) { super().merge('title' => 'Survey', 'exercise_type' => 'survey', 'user_state' => 'submitted') }

      it 'shows the item as completed' do
        render_inline(component)

        expect(page).to have_css("[aria-label='Survey']")
        expect(page).to have_css("[data-tooltip='Survey']")
        expect(page).to have_css('.fa-clipboard-list-check')
        expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
        expect(page).to have_css('.section-progress__material-item--completed')
        expect(page).to have_no_css('.section-progress__material-item--critical')
        expect(page).to have_no_css('.section-progress__material-item--warning')
      end
    end

    context 'that has been visited and completed (graded)' do
      let(:item) { super().merge('title' => 'Survey', 'exercise_type' => 'survey', 'user_state' => 'graded') }

      it 'shows the item as completed' do
        render_inline(component)

        expect(page).to have_css("[aria-label='Survey']")
        expect(page).to have_css("[data-tooltip='Survey']")
        expect(page).to have_css('.fa-clipboard-list-check')
        expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
        expect(page).to have_css('.section-progress__material-item--completed')
        expect(page).to have_no_css('.section-progress__material-item--critical')
        expect(page).to have_no_css('.section-progress__material-item--warning')
      end
    end
  end

  context 'for a video item' do
    let(:item) { super().merge('title' => 'Video item', 'content_type' => 'video', 'exercise_type' => nil, 'max_points' => 0) }

    context 'that is not yet visited' do
      let(:item) { super().merge('user_state' => 'new') }

      it 'shows the item as not yet visited' do
        render_inline(component)

        expect(page).to have_css("[aria-label='Video item']")
        expect(page).to have_css("[data-tooltip='Video item']")
        expect(page).to have_css('.fa-video')
        expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
        expect(page).to have_css('.section-progress__material-item')
        expect(page).to have_no_css('.section-progress__material-item--completed')
        expect(page).to have_no_css('.section-progress__material-item--critical')
        expect(page).to have_no_css('.section-progress__material-item--warning')
      end
    end

    context 'that has been visited' do
      let(:item) { super().merge('user_state' => 'visited') }

      it 'shows the item as completed' do
        render_inline(component)

        expect(page).to have_css("[aria-label='Video item']")
        expect(page).to have_css("[data-tooltip='Video item']")
        expect(page).to have_css('.fa-video')
        expect(page).to have_link(href: "/courses/#{course.course_code}/items/MuWLdgp3ovAznAJohFLuT")
        expect(page).to have_css('.section-progress__material-item--completed')
        expect(page).to have_no_css('.section-progress__material-item--critical')
        expect(page).to have_no_css('.section-progress__material-item--warning')
      end
    end
  end
end
