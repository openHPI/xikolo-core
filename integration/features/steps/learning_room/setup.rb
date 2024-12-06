# frozen_string_literal: true

module Steps
  module LearningRoom
    module Setup
      # too many steps otherwise
      Given(/^a basic course setup exists$/) do
        send 'Given an active course was created'
        send 'Given I am a confirmed user'
        send 'Given I am enrolled in the active course'
        send 'Given I am logged in'
      end

      def create_learning_room(attrs = {})
        course = context.fetch :course
        data = {
          name: 'test group',
          course_id: course['id'],
          is_open: true,
        }

        data.merge! attrs
        data.compact!

        Server[:collabspace].api.rel(:learning_room).post(data).value!
      end

      def update_learning_room(data)
        context.with :learning_room do |room|
          params = {id: room.id}
          Server[:collabspace].api.rel(:learning_room).patch(data, params).value!
        end
      end

      def create_membership(user, attrs)
        context.with :learning_room do |learning_room|
          data = {
            user_id: user['id'],
            learning_room_id: learning_room['id'],
          }

          data.merge! attrs
          data.compact!

          Server[:collabspace].api.rel(:membership).post(data).value!
        end
      end

      Given 'a collab space exists' do
        context.assign(
          :learning_room,
          create_learning_room
        )
      end

      Given 'a collab space team exists' do
        context.assign(
          :learning_room,
          create_learning_room(kind: 'team', is_open: false)
        )
      end

      Given 'the collab space is private' do
        update_learning_room is_open: false
      end

      Given 'the collab space is a team' do
        update_learning_room is_open: false, kind: 'team'
      end

      Given 'I am a member of this team' do
        context.with :user do |user|
          create_membership user, status: 'admin'
        end
      end

      Given 'the team has members' do
        context.with :course do |course|
          member = create_user
          enroll_user_in_course member, course
          context.assign :team_member, member
          create_membership member, status: 'admin'
        end
      end

      When(/^I create a Learning Room$/) do
        click_on 'Collab Space'
        click_on 'Create new Collab Space'
        fill_in 'Name', with: 'Test Room'
        click_on 'Create Collab Space'
      end

      Then(/^I should see the Learning Room in the list$/) do
        context.with :course do |course|
          visit "/courses/#{course['course_code']}/learning_rooms"
        end
        expect(page).to have_content 'Test Room'
      end
    end
  end
end

Gurke.config.include Steps::LearningRoom::Setup
