# frozen_string_literal: true

module Course
  class EntryActionPreview < ViewComponent::Preview
    # Uses development seed data without creating courses, enrollments, or sessions.
    def enroll(course_code: 'geo2013')
      course = ::CourseService::Course.find_by!(course_code:)
      user = ::CurrentUser::AnonymousUser.new(context_id: course.id)

      render_action(course, user)
    end

    def enter(course_code: 'geo2013')
      course = ::CourseService::Course.find_by!(course_code:)
      enrollment = course.enrollments.active.includes(:user).first!
      user = ::CurrentUser::User.new(
        context_id: course.id,
        session: ::AccountService::Session.new(user: enrollment.user)
      )

      render_action(course, user)
    end

    private

    def render_action(course, user)
      render ::Course::BottomBar.new do |bar|
        bar.with_primary_action do
          bar.render ::Course::EntryAction.new(course_id: course.id, user:)
        end
      end
    end
  end
end
