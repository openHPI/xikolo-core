# frozen_string_literal: true

require 'spec_helper'

describe 'Course Syllabus', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course: course) }

  let!(:non_previewable_items) do
    Array.new(2) do |i|
      video = create(:video)
      create(:'course_service/item',
        section: section,
        title: "Restricted Video #{i}",
        content: video,
        open_mode: false)
    end
  end

  let!(:previewable_item) do
    video = create(:video)
    create(:'course_service/item',
      section: section,
      title: 'Previewable Video',
      content: video,
      open_mode: true)
  end

  describe 'as a logged in and enrolled user' do
    let(:user) { create(:'account_service/user') }

    before do
      sign_in(user: user)
      enroll_in(course)
    end

    it 'visits the syllabus page and views a non-previewable item' do
      visit "/learn/#{course.course_code}/overview"

      non_previewable_items.each do |item|
        expect(page).to have_text(item.title)
      end
      expect(page).to have_text(previewable_item.title)

      expect(page).to have_no_text("The listed learning units belong to the course #{course.title}")

      click_on non_previewable_items.first.title

      expect(page).to have_current_path(%r{/learn/#{course.course_code}/items/})
      expect(page).to have_text(non_previewable_items.first.title)
    end
  end

  describe 'as a logged in but unenrolled user' do
    let(:user) { create(:'account_service/user') }

    before do
      sign_in(user: user)
    end

    context 'with open mode being enabled', :wip do
      before do
        xi_config <<~YML
          open_mode:
            enabled: true
            default_value: true
        YML
      end

      it 'views the syllabus in open mode' do
        visit "/learn/#{course.course_code}/overview"

        non_previewable_items.each do |item|
          expect(page).to have_text(item.title)
        end
        expect(page).to have_text(previewable_item.title)

        expect(page).to have_text("The listed learning units belong to the course #{course.title}")

        find('p', text: non_previewable_items.first.title).hover

        expect(page).to have_text('This learning unit cannot be previewed. Please enroll for the course to proceed.')

        click_on previewable_item.title

        expect(page).to have_current_path(%r{/learn/#{course.course_code}/items/})
        expect(page).to have_text(previewable_item.title)
      end
    end

    context 'with open mode being disabled' do
      before do
        xi_config <<~YML
          open_mode:
            enabled: false
            default_value: false
        YML
      end

      it 'is redirected and prompted to enroll' do
        visit "/learn/#{course.course_code}/overview"

        expect(page).to have_current_path("/learn/#{course.course_code}")
      end
    end
  end

  describe 'as an anonymous user' do
    context 'with open mode being disabled' do
      before do
        xi_config <<~YML
          open_mode:
            enabled: false
            default_value: false
        YML
      end

      it 'is redirected and prompted to log in' do
        visit "/learn/#{course.course_code}/overview"

        expect(page).to have_current_path("/learn/#{course.course_code}")
      end
    end

    context 'with open mode being enabled' do
      before do
        xi_config <<~YML
          open_mode:
            enabled: true
            default_value: true
        YML
      end

      it 'views the syllabus in open mode' do
        visit "/learn/#{course.course_code}/overview"

        expect(page).to have_text("The listed learning units belong to the course #{course.title}")

        find('p', text: non_previewable_items.first.title).hover

        expect(page).to have_text('This learning unit cannot be previewed. Please enroll for the course to proceed.')

        click_on previewable_item.title

        expect(page).to have_current_path(%r{/learn/#{course.course_code}/items/})
        expect(page).to have_text(previewable_item.title)
      end
    end
  end
end
