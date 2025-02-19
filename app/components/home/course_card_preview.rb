# frozen_string_literal: true

module Home
  # @label Course cards
  class CourseCardPreview < ViewComponent::Preview
    # Needed for previews with course reactivation button
    Xikolo.config.voucher['enabled'] = true

    # Appears collapsed on default, expands on hover.
    #
    # Contains basic metadata of a course in collapsed state.
    # In the hovered state it includes teachers, course abstract and action buttons.
    #
    # @label Expandable
    def expandable
      render Home::CourseCard.new(active_course)
    end

    # Passing an enrollment object for the user has effects on the available buttons
    #
    # @label Expandable with enrolled user
    def expandable_with_enrolled_user
      render Home::CourseCard.new(ended_course_with_reactivation, user: registered_user, enrollment:)
    end

    # A card with actions moves the 'Details' button in a dropdown where more links can be added
    #
    # @label With actions
    def with_actions
      render Home::CourseCard.new(active_course, user: registered_user) do |c|
        c.with_action { '<a href=#>Extra button</a>'.html_safe }
      end
    end

    # The 'compact' variant respects user specifics (i.e. by showing buttons), but omits
    # additional details such as teacher names and the course abstract.
    #
    # Meant to be used for lists of courses the user knows well, e.g. enrolled
    # courses on the user dashboard.
    #
    # @label Compact
    def compact
      render Home::CourseCard.new(active_course, user: registered_user, enrollment:, type: 'compact')
    end

    # Just like expandable cards, it moves the 'Details' button in a dropdown where more links can be added
    #
    # @label Compact with actions
    def compact_with_actions
      render Home::CourseCard.new(active_course, user: registered_user, type: 'compact') do |c|
        c.with_action { '<a href=#>Extra button</a>'.html_safe }
      end
    end

    # A special case is the reactivation button,
    # which is placed in the dropdown on the compact type.
    #
    # @label Compact with reactivation action
    def compact_with_reactivation
      render Home::CourseCard.new(ended_course_with_reactivation, user: registered_user, enrollment:, type: 'compact')
    end

    private

    COURSE_ID = SecureRandom.uuid
    COURSE_ID_2 = SecureRandom.uuid
    ENROLLMENT_ID = SecureRandom.uuid
    USER_ID = SecureRandom.uuid

    private_constant :ENROLLMENT_ID, :COURSE_ID, :COURSE_ID_2, :USER_ID

    def active_course
      Catalog::Course.new({
        id: COURSE_ID,
        course_code: 'databases',
        title: 'Everything about databases',
        teacher_text: 'Prof. D. B. Expert',
        abstract: 'Tables, rows and columns; all day long',
        start_date: 2.weeks.ago,
        end_date: 3.weeks.from_now,
        lang: 'en',
        fixed_classifiers: [],
        roa_enabled: true,
      })
    end

    def ended_course_with_reactivation
      Catalog::Course.new({
        id: COURSE_ID_2,
        course_code: 'databases',
        title: 'Everything about databases',
        teacher_text: 'Prof. D. B. Expert',
        abstract: 'Tables, rows and columns; all day long',
        start_date: 3.weeks.ago,
        end_date: 2.weeks.ago,
        lang: 'en',
        fixed_classifiers: [],
        roa_enabled: true,
        on_demand: true,
        status: 'active',
      })
    end

    def enrollment
      ::Course::Enrollment.new({
        id: ENROLLMENT_ID,
        course_id: COURSE_ID,
        user_id: USER_ID,
      })
    end

    def registered_user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'features' => {'course_reactivation' => true},
        'user_id' => USER_ID,
        'user' => {'anonymous' => false},
      })
    end
  end
end
