# frozen_string_literal: true

class Course::CoursesController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper

  inside_course

  before_action :ensure_canonical_course_url, only: %i[show]
  before_action :redirect_from_course_page, only: %i[show]

  respond_to :json

  def teaser_signed_url
    authorize! 'course.course.show'
    video = the_course.visual&.video
    stream = video&.bunny_stream
    raise Status::NotFound unless video&.display_streams&.one? && stream&.ready?

    response.headers['Cache-Control'] = 'no-store'
    redirect_to BunnySignedURL.new.call(stream.provider_video_id, expires_in: 600).fetch(:video), allow_other_host: true
  end

  def show
    # Some courses' visibility is restricted to certain user groups (affiliated or partner courses).
    # Ensure the user is allowed to see this course.
    unless current_user.allowed? 'course.course.show'
      add_flash_message :error, t(:'flash.error.not_authorized')
      return redirect_to dashboard_path, status: :see_other
    end

    @teacher_list_presenter = Course::TeacherListPresenter.for_course the_course

    enrollments = Array.wrap(my_enrollment)

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
    @current_item = Item::FindCurrent.call(
      course: the_course,
      user_id: current_user.id,
      preview: current_user.allowed?('course.content.access')
    )
    raise Acfs::ResourceNotFound if @current_item.nil?

    redirect_to course_item_path(the_course.course_code,
      short_uuid(@current_item.id)), status: :see_other
  rescue Acfs::ResourceNotFound # No redirectable item found!
    add_flash_message :notice, t(:'flash.notice.course_not_published')
    redirect_to course_path(params[:id]), status: :see_other
  end

  def course_nav_tab
    :details
  end

  def course_area_variant
    :full_width
  end

  protected

  # Fix course receiving
  def request_course
    course = CourseService::Course.by_identifier(params[:id]).take
    if course.nil?
      raise Status::NotFound
    end

    course
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

    CourseService::Enrollment.find_by(
      user_id: current_user.id, course_id: the_course.id, deleted: false
    )
  end
end
