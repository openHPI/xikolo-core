# frozen_string_literal: true

module Course
  ##
  # A presenter for the course area layout
  #
  class LayoutPresenter
    # Initialize a new presenter
    #
    # @param course [Xikolo::Course::Course]
    # @param user [Xikolo::Common::Auth::CurrentUser::Base]
    def initialize(course, user)
      @course = course
      @user = user
    end

    delegate :id, :title, :lang, :external?, to: :@course

    include Rails.application.routes.url_helpers

    def teachers
      @course.teacher_text
    end

    # get a "full" state, used for the ribbon
    def fullstate
      @course.fullstate
    end

    def nav
      @nav ||= CourseNav.items_for(@user, @course)
    end

    def teacher_nav
      @teacher_nav ||= CourseTeacherNav.items_for(@user, @course)
    end

    def admin_action_link(view_context:)
      # Check if the user has teacher permissions and can access the page where
      # the action (recalculation) is triggered (course settings page).
      return unless @user.allowed?('course.content.edit')
      return if teacher_nav.empty?
      return unless needs_recalculation?

      AdminAction.new(view_context, @course)
    end

    def back_to_course_link(view_context:, in_teacher_context:)
      return unless @user.allowed_any?('course.course.edit', 'course.content.edit')

      if in_teacher_context
        BackToCourse.from_teacher_context(view_context, @course)
      else
        BackToCourse.from_course_context(view_context, @course)
      end
    end

    def deadlines
      DeadlinesPresenter.new(@user, @course)
    end

    private

    def needs_recalculation?
      return false unless recalculation_enabled?

      @user.allowed?('course.course.recalculate') &&
        the_course.needs_recalculation?
    end

    def recalculation_enabled?
      Xikolo.config.persisted_learning_evaluation.present?
    end

    def the_course
      @the_course ||= ::Course::Course.find(@course.id)
    end

    class AdminAction
      def initialize(context, course)
        @context = context
        @course = course
      end

      def url
        @context.course_sections_path(@course)
      end

      def text
        I18n.t(:'courses.nav.admin.alerts')
      end

      def display?
        !@context.current_page? url
      end
    end

    class BackToCourse
      class << self
        def from_teacher_context(context, course)
          new(context, url: context.course_path(course), text: I18n.t(:'courses.nav.admin.back'))
        end

        def from_course_context(context, course)
          new(context, url: context.course_sections_path(course), text: I18n.t(:'courses.nav.admin.back_admin'))
        end
      end

      def initialize(context, url:, text:)
        @context = context
        @url = url
        @text = text
      end

      attr_reader :url, :text

      def display?
        !@context.current_page? @url
      end
    end
  end
end
