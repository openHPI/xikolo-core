# frozen_string_literal: true

module Steps
  module Course
    def create_course(attrs = {})
      data = {
        lang: 'en',
        status: 'active',
        abstract: 'This is a abstract for a course.',
        course_code: 'the_course',
        start_date: Time.now.in_time_zone - (3600 * 24),
        end_date: Time.now.in_time_zone + (3600 * 24 * 7),
        title: 'A Course :-)',
        welcome_mail: 'welcome to the_course',
        description: 'A little bit more of text.',
      }

      data.merge! attrs
      data.compact!

      Server[:course].api.rel(:courses).post(data).value!
    end

    def enroll(the_course = :course)
      context.with :user, the_course do |user, course|
        enroll_user_in_course user, course
      end
    end

    def enroll_user_in_course(user, course)
      enrollment = {
        user_id: user['id'],
        course_id: course['id'],
      }
      Server[:course].api.rel(:enrollments).post(enrollment).value!
    end

    def join_global_group(group)
      context.with :user do |user|
        join_user_into_group user, group
      end
    end

    def join_special_group(group)
      context.with :user, :course do |user, course|
        join_user_into_special_group user, course, group
      end
    end

    def join_user_into_special_group(user, course, group)
      join_user_into_group user, ['course', course['course_code'], group].join('.')
    end

    def join_user_into_group(user, group_name)
      Server[:account].api.rel(:memberships).post({
        group: group_name,
        user: user['id'],
      }).value!
    end

    def lock_course_forum(course)
      Server[:course].api.rel(:course).patch(
        {forum_is_locked: true},
        params: {id: course['id']}
      ).value!
    end

    Given 'the course forum is locked' do
      context.with :course do |course|
        lock_course_forum course
      end
    end

    Given 'an active course was created' do
      context.assign :course, create_course
    end

    Given 'an upcoming course was created' do
      context.assign :course, create_course(
        start_date: 2.weeks.from_now,
        end_date: 8.weeks.from_now
      )
    end

    Given 'an active partner course was created' do
      context.assign :course, create_course(
        title: 'Partner Course',
        course_code: 'partner1',
        groups: ['company.partner']
      )
    end

    Given 'an archived course was created' do
      context.assign :archived_course, create_course(
        status: 'archive',
        start_date: 20.days.ago,
        end_date: 10.days.ago,
        course_code: 'archived',
        title: 'The Archived Course'
      )
    end

    Given 'an unpublished course was created' do
      context.assign :course, create_course(status: 'preparation')
    end

    Given 'a hidden course was created' do
      context.assign :course, create_course(hidden: true, course_code: 'hidden', title: 'A Hidden Course')
    end

    Given 'an active course with a locked forum was created' do
      context.assign :course, create_course(forum_is_locked: true)
    end

    Given "an 'invite only' course was created" do
      context.assign :course, create_course(invite_only: true)
    end

    Given 'I am enrolled in the course' do
      enroll
    end

    Given 'I am enrolled in the active course' do
      send :'Given I am enrolled in the course'
    end

    Given 'I am enrolled in the archived course' do
      enroll :archived_course
    end

    Given 'the additional user is enrolled' do
      context.with :additional_user, :course do |user, course|
        enroll_user_in_course user, course
      end
    end

    Given 'there exist some teachers' do
      account_service = Server[:account].api
      course_service = Server[:course].api
      teachers = Factory.create_list(:user, 5)
      teachers.map! do |data|
        account_service.rel(:users).post(data).then do |user|
          data.each_pair {|key, value| user[key] ||= value }
          course_service.rel(:teachers).post({
            id: user['id'],
            name: user['name'],
            description: {
              en: 'Some text',
            },
          })
          user
        end
      end
      teachers.map!(&:value!)

      context.assign :teachers, teachers
    end

    Given 'users are enrolled in the course' do
      send :'Given there exist some users'
      context.with :users, :course do |users, course|
        users.each do |user|
          enroll_user_in_course user, course
        end
      end
    end

    Given 'I am logged in as a global course manager' do
      context.assign :user, create_user
      join_global_group 'xikolo.admins'
      send :'Given I am logged in'
    end

    Given 'I am logged in as a course admin' do
      context.assign :user, create_user
      enroll
      join_special_group 'admins'
      send :'Given I am logged in'
    end

    Given 'I am logged in as a course admin in the archived course' do
      context.assign :user, create_user
      enroll :archived_course
      context.with :user, :archived_course do |user, course|
        join_user_into_special_group user, course, 'admins'
      end
      send :'Given I am logged in'
    end

    Given 'there are two course admins' do
      context.with :course do |course|
        admins = Array.new(2) do
          user = create_user
          enroll_user_in_course user, course
          join_user_into_special_group user, course, 'admins'
          user
        end
        context.assign :course_admins, admins
      end
    end

    Given 'there is a course admin' do
      context.assign :admin, create_user
      join_user_into_special_group context.fetch(:admin), context.fetch(:course), 'admins'
    end

    Given 'an active course with a section was created' do
      send :'Given an active course was created'
      send :'Given an active section was created'
    end

    Given 'an active course with teachers was created' do
      send :'Given an active course was created'
      send :'Given there exist some users'
      context.assign :teacher_group_members, context.fetch(:users)[0..2]
      context.with :teacher_group_members, :course do |teachers, course|
        teachers.map do |teacher|
          Server[:account].api.rel(:memberships).post({
            group: ['course', course['course_code'], 'teachers'].join('.'),
            user: teacher['id'],
          }).value!
        end
      end
    end

    Given 'the course records are released' do
      context.with :course do |course|
        Server[:course].api.rel(:course).put(
          {records_released: true},
          params: {id: course['id']}
        ).value!
      end
    end

    When 'I try to visit the course content' do
      click_on 'Learnings'
    end

    When 'I move the lower section up' do
      sections = page.all('[data-behavior="section-handle"]')
      sections[1].drag_to(sections[0])
    end

    Then 'there should be no course' do
      expect(page).to_not have_selector '.course-card'
    end

    Then 'the course should be listed' do
      context.with :course do |course|
        expect(page).to have_content course['title']
      end
    end

    Then 'the course should not be listed' do
      expect(page).to have_content 'There are no courses available yet.'
    end

    Then 'I should see course details' do
      context.with :course do |course|
        expect(page).to have_content course['title']
        expect(page).to have_content course['description']
      end
    end

    Then 'I should see the course navigation' do
      context.with :course do |_course|
        expect(page).to have_content 'Learnings'
        expect(page).to have_selector('nav.navigation-tabs', count: 1)
      end
    end

    Then 'I should not see the course teacher navigation' do
      context.with :course do |_course|
        expect(page).to_not have_selector('#teacher-nav')
      end
    end

    Then(/I should see a countdown for "(.*)"/) do |label|
      expect(page).to have_content label
    end

    Then 'I see a message that there is no public course content' do
      expect(page).to have_content 'There is no public course content yet.'
    end

    Then 'I see a message that I should enroll in the course' do
      expect(page).to have_content 'You are not enrolled for this course.'
    end

    Then 'I see a message that I should login to proceed' do
      expect(page).to have_content 'Please log in to proceed.'
    end

    Then(/I see the course (.*)/) do |title|
      within('div.course-card') do
        expect(page).to have_content(title)
      end
    end

    Then 'I should see it in the correct order' do
      # Ensure the backend handled the request to change the order
      visit current_path

      first_section = find('ul.sections > li:first-child')
      last_section = find('ul.sections > li:last-child')

      expect(first_section).to have_content('Week 1')
      expect(last_section).to have_content('A very important section!')
    end
  end
end

Gurke.configure {|c| c.include Steps::Course }
