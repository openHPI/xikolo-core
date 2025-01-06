# frozen_string_literal: true

class Course::CoursesController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper
  inside_course

  before_action :ensure_canonical_course_url, only: %i[show]
  before_action :redirect_from_course_page, only: %i[show]
  before_action :set_no_cache_headers

  respond_to :json

  def show
    @infos = []

    # Some courses' visibility is restricted to certain user groups (affiliated or partner courses).
    # Ensure the user is allowed to see this course.
    unless current_user.allowed? 'course.course.show'
      add_flash_message :error, t(:'flash.error.not_authorized')
      return redirect_to dashboard_path
    end

    # 1. Fetch teacher info
    @teacher_list_presenter = Course::TeacherListPresenter.for_course the_course

    # 2. Sections (for content)
    # Also check if there is a section description, if not we going to hide stuff in the view
    @sections = the_course.sections do |sections|
      @show_section_info = sections.any? {|s| s.description.present? }
    end

    # 3. Items for featured items sidebar widget
    @featured_items = Course::Course.find(the_course.id)
      .items
      .where(content_type: 'video', featured: true).map do |item|
      FeaturedItemPresenter.build(item, the_course)
    end

    enrollments = Array.wrap(my_enrollment)

    @large_preview = CourseLargePreviewPresenter.build the_course, current_user, enrollments
    if @large_preview.show_social_media_buttons?
      @social_sharing = SocialSharingPresenter.new(
        context: :course,
        options: {
          site: Xikolo.config.site_name,
          title: the_course.title,
          course_url: course_url(the_course.course_code),
        }
      )
    end
    @course_presenter = Course::CourseDetailsPresenter.build the_course, enrollments, current_user

    if current_user.anonymous? && !cookies.signed[:stored_location]
      store_location course_path(the_course.course_code)
    end

    Acfs.run

    meta = @course_presenter.meta_tags
    set_page_title(*meta.delete(:title))
    set_meta_tags meta
  end

  def resume
    # Don't try to resume if course hasn't started yet (except for authorized users)
    raise Acfs::ResourceNotFound unless the_course.was_available? || current_user.allowed?('course.content.access')

    # Ask course service for the item to forward to
    @current_item = Xikolo::Course::Item.find 'current', params: {
      course: the_course.id,
      user: current_user.id,
      preview: current_user.allowed?('course.content.access'),
    }
    Acfs.run

    redirect_to course_item_path(the_course.course_code,
      short_uuid(@current_item.id))
  rescue Acfs::ResourceNotFound # No redirectable item found!
    add_flash_message :notice, t(:'flash.notice.course_not_published')
    redirect_to course_path(params[:id])
  end

  protected

  # Fix course receiving
  def request_course
    Xikolo::Course::Course.find(params[:id])
  end

  def check_course_eligibility
    return if the_course.published?

    unless current_user.allowed? 'course.content.access'
      Rails.logger.debug 'NOT FOUND: course not published'
      raise Status::NotFound
    end
  end

  def auth_context
    the_course.context_id
  end

  def ensure_canonical_course_url
    # Check if we're at the canonical URL, means the parameter is
    # the correct written course code.
    return if the_course.course_code == params[:id]

    redirect_to course_url(the_course.course_code), status: :moved_permanently
  end

  def redirect_from_course_page
    return if PublicCoursePage.enabled?

    r = PublicCoursePage::Redirect.new(the_course, current_user)
    redirect_external(r.target) if r.redirect?
  end

  def my_enrollment
    return nil if current_user.anonymous?

    Course::Enrollment.find_by(
      user_id: current_user.id, course_id: the_course.id, deleted: false
    )
  end
end
