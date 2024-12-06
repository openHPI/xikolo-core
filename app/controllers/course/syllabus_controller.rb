# frozen_string_literal: true

class Course::SyllabusController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper
  inside_course

  before_action :set_no_cache_headers
  before_action :load_section_nav

  def show
    @course_progress = Course::ProgressPresenter.build current_user, the_course
    Acfs.run
    set_page_title the_course.title, t(:'courses.nav.syllabus')
    render(layout: 'course_area_two_cols')
  end

  private

  def auth_context
    the_course.context_id
  end

  def check_course_eligibility
    # inside_course checks whether a user is allowed
    # to access course content. Since the syllabus
    # (overview) is also available in open_mode, we
    # need to overwrite this check here.

    # Open mode does not matter when the user is enrolled
    super if current_user.allowed?('course.content.access.available')

    super if !Xikolo.config.open_mode['enabled'] || !open_mode?
  end

  def open_mode?
    return false unless current_user.feature?('open_mode')
    return false if the_course.invite_only || the_course.hidden

    previewable_items.any?
  end

  def previewable_items
    @previewable_items ||= Xikolo.api(:course).value!
      .rel(:items)
      .get(course_id: the_course.id, open_mode: true)
      .value!
  end
end
