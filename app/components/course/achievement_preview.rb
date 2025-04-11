# frozen_string_literal: true

module Course
  class AchievementPreview < ViewComponent::Preview
    # @!group
    def achievable
      render ::Course::Achievement.new(achievable_achievement, documents)
    end

    def achieved
      render ::Course::Achievement.new(achieved_achievement, documents)
    end

    def downloadable
      render ::Course::Achievement.new(downloadable_achievement, documents)
    end

    def unachievable
      render ::Course::Achievement.new(unachievable_achievement, documents)
    end

    def not_available
      render ::Course::Achievement.new(not_available_achievement, documents)
    end

    def open_badge
      render ::Course::Achievement.new(record_of_achievement, documents)
    end

    # @!endgroup

    private

    COURSE_ID = SecureRandom.uuid
    USER_ID = SecureRandom.uuid

    private_constant :COURSE_ID, :USER_ID

    def course
      Catalog::Course.new({id: COURSE_ID, course_code: 'course_code'})
    end

    def registered_user
      Xikolo::Common::Auth::CurrentUser.from_session({'user_id' => USER_ID, 'user' => {'anonymous' => false}})
    end

    def documents
      presenter = DocumentsPresenter.new(user_id: USER_ID, course: course, current_user: registered_user)
      presenter.define_singleton_method(:open_badge?) { true }
      presenter.define_singleton_method(:open_badge_enabled?) { true }
      presenter
    end

    def achievable_achievement
      {
        'name' => 'Achievable Achievement',
        'description' => 'This is an achievable achievement. You can do it!',
        'achieved' => false,
        'achievable' => true,
        'requirements' => [
          {'description' => 'Requirement 1', 'achieved' => true},
          {'description' => 'Requirement 2', 'achieved' => false},
        ],
        'download' => {'type' => 'progress'},
      }
    end

    def record_of_achievement
      {
        'name' => 'Achievable Achievement',
        'type' => 'record_of_achievement',
        'description' => 'Record of achievement with an open badge.',
        'achieved' => true,
        'achievable' => true,
        'requirements' => [
          {'description' => 'Requirement 1', 'achieved' => true},
        ],
        'download' => {
          'type' => 'download',
          'available' => true,
          'url' => '#',
        },
      }
    end

    def achieved_achievement
      {
        'name' => 'Achieved Achievement',
        'description' => 'This is an achieved achievement. Congratulations!',
        'achieved' => true,
        'achievable' => false,
        'requirements' => [
          {'description' => 'Requirement 1', 'achieved' => true},
          {'description' => 'Requirement 2', 'achieved' => true},
        ],
        'download' => {
          'type' => 'download',
          'available' => false,
          'url' => '#',
          'description' => 'You can download a certificate here as soon as the records have been released.
            Please check back later.',
        },
      }
    end

    def downloadable_achievement
      {
        'name' => 'Downloadable Achievement',
        'description' => 'This is an achieved achievement. Congratulations! You can also download a certificate.',
        'achieved' => true,
        'achievable' => false,
        'requirements' => [
          {'description' => 'Requirement 1', 'achieved' => true},
          {'description' => 'Requirement 2', 'achieved' => true},
        ],
        'download' => {
          'type' => 'download',
          'available' => true,
          'url' => '#',
        },
      }
    end

    def unachievable_achievement
      {
        'name' => 'Unachievable Achievement',
        'description' => 'This achievement can no longer be achieved.',
        'achieved' => false,
        'achievable' => false,
        'requirements' => [
          {'description' => 'Requirement 1', 'achieved' => false},
          {'description' => 'Requirement 2', 'achieved' => false},
        ],
      }
    end

    def not_available_achievement
      {
        'name' => 'Achievement not available',
        'description' => 'There is no achievement of this kind possible.',
      }
    end
  end
end
