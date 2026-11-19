# frozen_string_literal: true

module Course
  class DetailsCardPreview < ViewComponent::Preview
    # Classifiers are looked up in the database; fake them for the preview.
    class PreviewPresenter < ::Course::CourseDetailsPresenter
      attr_accessor :categories, :manual_completion

      def category_titles
        categories
      end

      def mark_completed?
        manual_completion
      end
    end

    # @!group
    def default
      render ::Course::DetailsCard.new(presenter, enrollment_count: 1000)
    end

    def enrolled
      render ::Course::DetailsCard.new(
        presenter(enrollments: [enrollment], manual_completion: true),
        enrollment_count: 1000
      )
    end

    def upcoming
      render ::Course::DetailsCard.new(presenter(start_date: 3.weeks.from_now))
    end

    def enrolled_upcoming
      render ::Course::DetailsCard.new(presenter(enrollments: [enrollment], start_date: 3.weeks.from_now))
    end
    # @!endgroup

    private

    COURSE_ID = SecureRandom.uuid
    USER_ID = SecureRandom.uuid

    private_constant :COURSE_ID, :USER_ID

    def presenter(enrollments: nil, manual_completion: false, **)
      PreviewPresenter.new(course: course(**), user:, enrollments:).tap do |presenter|
        presenter.categories = ['Digital Justice', 'AI', 'Bias']
        presenter.manual_completion = manual_completion
      end
    end

    def course(**attrs)
      ::CourseService::Course.new(
        id: COURSE_ID,
        course_code: 'digital-justice',
        title: 'Digital Justice – How to get involved in a fairer AI future',
        alternative_teacher_text: 'Jennifer Fritz',
        abstract: 'Artificial intelligence has long since become part of your everyday life. From recommendation ' \
                  'algorithms in social media to generating birthday greetings – AI can be found almost everywhere ' \
                  'today. But AI systems are not neutral: they can reproduce and reinforce existing inequalities. ' \
                  'In this course, you will learn how bias gets into AI systems and what you can do about it.',
        course_format: 'project',
        lang: 'en',
        published: true,
        start_date: 2.weeks.ago,
        updated_at: 3.days.ago,
        **attrs
      )
    end

    def enrollment
      ::CourseService::Enrollment.new(id: SecureRandom.uuid, course_id: COURSE_ID, user_id: USER_ID)
    end

    # A logged-in learner without any special permissions.
    def user
      session = ::AccountService::Session.new(user: ::AccountService::User.new(id: USER_ID))
      ::CurrentUser::User.new(context_id: 'root', session:)
    end
  end
end
