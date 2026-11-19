# frozen_string_literal: true

module Course
  ##
  # A presenter for the course area layout
  #
  class LayoutPresenter
    # Initialize a new presenter
    #
    # @param course [CourseService::Course]
    # @param user [Xikolo::Common::Auth::CurrentUser::Base]
    def initialize(course, user)
      @course = course
      @user = user
    end

    delegate :id, :title, :lang, :course_code, to: :@course

    include Rails.application.routes.url_helpers

    def external?
      @course.external_course_url.present?
    end

    def nav
      @nav ||= CourseNav.items_for(@user, @course)
    end

    def pinboard_enabled?
      @course.pinboard_enabled
    end

    def was_available?
      @course.was_available?
    end

    # Enrolled learners, and staff who may access the content without enrolling.
    def content_accessible?
      @user.allowed_any?('course.content.access', 'course.content.access.available')
    end

    # Published announcements of the course the user has not read yet.
    def unread_announcements
      return NewsService::News.none unless @user.allowed?('course.content.access.available')

      NewsService::News.where(course_id: id).published.unread_by(@user.id)
    end

    def teacher_nav
      @teacher_nav ||= CourseTeacherNav.items_for(@user, @course)
    end

    # The trail leading to the current page inside the course, for +Global::Breadcrumbs+.
    def breadcrumbs(view_context:)
      [
        {url: root_path,
         icon: view_context.pixelart_icon('home', css_class: 'w-4 h-4'),
         aria_label: I18n.t('header.navigation.home')},
        {url: courses_path, text: I18n.t('header.navigation.courses')},
        {url: course_path(@course), text: @course.title},
        current_crumb(view_context),
      ].compact
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

    def status
      @course.status
    end

    private

    # The page the user is on, taken from the navigation tab it belongs to.
    def current_crumb(view_context)
      active = nav.find {|item| item.active?(view_context.request) }
      # The course detail page is already the third level, so do not repeat it.
      return if active.nil? || active.link == course_path(@course)

      {url: active.link, text: active.text}
    end

    def needs_recalculation?
      @user.allowed?('course.course.recalculate') &&
        the_course.needs_recalculation?
    end

    def the_course
      @the_course ||= ::CourseService::Course.find(@course.id)
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
          new(context,
            url: context.course_path(course),
            text: I18n.t(:'courses.nav.admin.back'),
            icon: context.pixelart_icon('learning_material', css_class: 'w-4 h-4'))
        end

        def from_course_context(context, course)
          new(context,
            url: context.course_sections_path(course),
            text: I18n.t(:'courses.nav.admin.back_admin'),
            icon: context.pixelart_icon('settings', css_class: 'w-4 h-4'))
        end
      end

      def initialize(context, url:, text:, icon:)
        @context = context
        @url = url
        @text = text
        @icon = icon
      end

      attr_reader :url, :text, :icon

      def display?
        !@context.current_page? @url
      end
    end
  end
end
