# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Course: Mark Completed', gen: 2, type: :feature do
  let(:user) { build(:'account:user') }
  let(:course) { create(:course, :archived, title: 'My course') }
  let(:enrollment) { create(:enrollment, course:, user_id: user['id']) }
  let(:enrollment_resource) do
    build(:'course:enrollment', :with_learning_evaluation,
      id: enrollment.id,
      user_id:  user['id'],
      course_id: course.id,
      url: "/enrollments/#{enrollment.id}")
  end

  before do
    stub_user(id: user['id'])
    Stub.request(:account, :get, "/users/#{user['id']}")
      .to_return Stub.json(user)
    Stub.request(
      :account, :post, '/tokens',
      body: hash_including(user_id: user['id'])
    ).to_return Stub.json({token: 'abc'})

    # Course stubs for the sidebar content.
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(user_id: user['id'], learning_evaluation: 'true')
    ).to_return Stub.json([enrollment_resource])
    Stub.request(
      :course, :get, '/next_dates',
      query: {user_id: user['id']}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/courses',
      query: {promoted_for: user['id']}
    ).to_return Stub.json([])
  end

  context 'with current course (i.e., course that has ended but was not yet completed)' do
    it 'marks the course as completed' do
      visit '/dashboard'

      expect(page).to have_content 'My current courses'
      page.find(:xpath, "//*[text()='My current courses']//ancestor::*[@class='course-group']") do |elem|
        expect(elem).to have_content 'My course'
      end
      expect(page).to have_content 'My upcoming courses'
      expect(page).to have_content 'You are not enrolled in any upcoming courses.'
      expect(page).to have_no_content 'My completed courses'

      expect(enrollment).not_to be_completed

      find('[aria-label="More actions"]').click
      within '[data-behaviour="menu-dropdown"]' do
        click_on 'Mark as completed'
      end
      expect(page).to have_content 'Are you sure?'
      within '[role=dialog][aria-modal=true]' do
        click_on 'Yes, sure'
      end
      expect(page).to have_content 'The course was successfully marked as completed.'
      expect(enrollment.reload).to be_completed

      expect(page).to have_no_content 'My current courses'
      expect(page).to have_content 'My upcoming courses'
      expect(page).to have_content 'You are not enrolled in any upcoming courses.'
      expect(page).to have_content 'My completed courses'
      page.find(:xpath, "//*[text()='My completed courses']//ancestor::*[@class='course-group']") do |elem|
        expect(elem).to have_content 'My course'
      end

      expect(page).to have_no_link 'Mark as completed', visible: :all
    end
  end

  context 'with already completed course' do
    let(:enrollment) { create(:enrollment, course:, user_id: user['id'], completed: true) }
    let(:enrollment_resource) do
      build(:'course:enrollment:evaluated', :with_learning_evaluation,
        id: enrollment.id,
        user_id:  user['id'],
        course_id: course.id)
    end

    it 'there is no course that can be marked as completed' do
      visit '/dashboard'

      expect(page).to have_no_content 'My current courses'
      expect(page).to have_content 'My upcoming courses'
      expect(page).to have_content 'You are not enrolled in any upcoming courses.'
      expect(page).to have_content 'My completed courses'
      page.find(:xpath, "//*[text()='My completed courses']//ancestor::*[@class='course-group']") do |elem|
        expect(elem).to have_content 'My course'
      end

      expect(page).to have_no_link 'Mark as completed', visible: :all
    end
  end

  context 'with active course' do
    let(:course) { create(:course, :active, title: 'My course') }

    it 'the course can be marked as completed' do
      visit '/dashboard'

      expect(page).to have_content 'My current courses'
      page.find(:xpath, "//*[text()='My current courses']//ancestor::*[@class='course-group']") do |elem|
        expect(elem).to have_content 'My course'
      end
      expect(page).to have_content 'My upcoming courses'
      expect(page).to have_content 'You are not enrolled in any upcoming courses.'
      expect(page).to have_no_content 'My completed courses'

      expect(page).to have_link 'Mark as completed', visible: :all
    end
  end

  context 'with upcoming course' do
    let(:course) { create(:course, :upcoming, title: 'My course') }

    it 'there is no course that can be marked as completed' do
      visit '/dashboard'

      expect(page).to have_no_content 'My current courses'
      expect(page).to have_content 'My upcoming courses'
      page.find(:xpath, "//*[text()='My upcoming courses']//ancestor::*[@class='course-group']") do |elem|
        expect(elem).to have_content 'My course'
      end
      expect(page).to have_no_content 'You are not enrolled in any upcoming courses.'
      expect(page).to have_no_content 'My completed courses'

      expect(page).to have_no_link 'Mark as completed', visible: :all
    end
  end

  context 'with self-paced course' do
    let(:course) { create(:course, :self_paced, title: 'My course') }

    it 'the course can be marked as completed' do
      visit '/dashboard'

      expect(page).to have_content 'My current courses'
      page.find(:xpath, "//*[text()='My current courses']//ancestor::*[@class='course-group']") do |elem|
        expect(elem).to have_content 'My course'
      end
      expect(page).to have_content 'My upcoming courses'
      expect(page).to have_content 'You are not enrolled in any upcoming courses.'
      expect(page).to have_no_content 'My completed courses'

      expect(page).to have_link 'Mark as completed', visible: :all
    end
  end
end
