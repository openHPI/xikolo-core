# frozen_string_literal: true

module Course
  class KeyFactsPreview < ViewComponent::Preview
    # Classifiers are looked up in the database; fake the level for the preview.
    class PreviewPresenter < ::Course::CourseDetailsPresenter
      def level
        'Expert'
      end
    end

    # @!group
    def default
      render ::Course::KeyFacts.new(PreviewPresenter.new(course:, user:))
    end

    def without_level_and_certificate
      render ::Course::KeyFacts.new(
        ::Course::CourseDetailsPresenter.new(course: course(roa_enabled: false, cop_enabled: false), user:)
      )
    end
    # @!endgroup

    private

    def course(**attrs)
      ::CourseService::Course.new(id: SecureRandom.uuid, course_code: 'digital-justice', lang: 'de', **attrs)
    end

    def user
      ::CurrentUser::AnonymousUser.new(context_id: 'root')
    end
  end
end
