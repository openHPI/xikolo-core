# frozen_string_literal: true

module Steps
  module Forum
    module CourseSubscriptions
      When 'I subscribe to the current course' do
        context.with :user, :course do |user, course|
          Server[:pinboard].api.rel(:course_subscriptions).post({
            user_id: user['id'],
            course_id: course['id'],
          }).value!
        end
      end

      Given 'I am subscribed to the current course' do
        send :'When I subscribe to the current course'
      end

      When 'I unsubscribe from the current course' do
        context.with :user, :course do |user, course|
          subs = Server[:pinboard].api.rel(:course_subscriptions).get({
            user_id: user['id'],
            course_id: course['id'],
          }).value!
          if subs.any?
            Server[:pinboard].api.rel(:course_subscription).delete({id: subs.first['id']}).value!
          end
        end
      end

      When 'another user posts a new topic in the current course' do
        context.with :course do |course|
          other = Factory.create(:user)
          other = Server[:account].api.rel(:users).post(other).value!
          Server[:pinboard].api.rel(:questions).post({
            user_id: other['id'],
            course_id: course['id'],
            title: 'New Topic',
            text: 'Body',
          }).value!
        end
      end

      Then 'I receive a course subscription notification email' do
        context.with :user do |user|
          open_email fetch_emails(to: user['email'], subject: 'There is a new topic in the forum.').last
          expect(page).to have_content 'Discussion Forum Activity'
          expect(page).to have_content 'posted in the forum'
          expect(page).to have_content 'Body'
        end
      end

      Then 'I do not receive a course subscription notification email' do
        context.with :user do |user|
          expect do
            fetch_emails to: user['email'], subject: 'There is a new topic in the forum.', timeout: 15
          end.to raise_error(Timeout::Error)
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Forum::CourseSubscriptions }
