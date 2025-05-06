# frozen_string_literal: true

module CourseContextHelper
  def course_layout
    @course_layout ||= Course::LayoutPresenter.new(the_course, current_user)
  end

  def the_section_nav
    if promises.key? :section_nav
      promises[:section_nav]
    else
      raise 'Section nav not loaded!'
    end
  end

  def self.included(base_controller)
    # for some reason some other module seems to want to include this
    return unless base_controller.respond_to? :before_action

    base_controller.helper_method :course_layout
    base_controller.helper_method :hide_course_nav?

    class << base_controller
      def inside_course(**)
        layout('course_area', **)
        before_action(:check_course_eligibility, **)
      end
    end
  end

  def check_course_eligibility
    return if current_user.allowed?('course.content.access')

    # TODO: improve checks
    if !the_course.was_available?
      unless the_course.published?
        Rails.logger.debug 'NOT FOUND: course not published'
        raise Status::NotFound
      end

      raise Status::Redirect.new 'course not started yet', course_url(the_course.course_code)
    elsif current_user.anonymous?
      store_location
      add_flash_message :error, t(:'flash.error.login_to_proceed')
      raise Status::Redirect.new 'user not logged in', course_url(the_course.course_code)
    else
      unless current_user.allowed?('course.content.access.available')
        add_flash_message :error, I18n.t(:'flash.error.not_enrolled')
        raise Status::Redirect.new 'user has no enrollment', course_url(the_course.course_code)
      end
    end
  end

  def hide_course_nav?
    false
  end

  protected

  # functions around the current course
  def request_course
    Xikolo::Course::Course.find params[:course_id]
  end

  # the current section
  def the_section
    promises[:section] ||= request_section.tap do |promise|
      Acfs.on(promise) do |section|
        next if section.nil? || section.was_available?

        unless current_user.allowed?('course.content.access')
          # this will redirect to the last visited item or to the first public or to the course info
          raise Status::Redirect.new 'Section not available', course_resume_path(the_course.id)
        end
      end
    end
  end

  def request_section
    if params[:section_id] && params[:section_id] != 'technical_issues'
      Xikolo::Course::Section.find UUID(params[:section_id])
    else
      # no section:
      dummy_resource_delegator nil
    end
  end

  # the current item
  def the_item
    promises[:item] ||= request_item.then do |promise|
      promise.tap do |item|
        if item.blank? || item_available?(item) || (item['featured'] && item['published'])
          next
        end
        unless current_user.allowed?('course.content.access')
          # this will redirect to the last visited item or to the first public or to the course info
          raise Status::Redirect.new 'Item not available', course_resume_path(the_course.id)
        end
      end
    end
  end

  def request_item
    nil
  end

  def load_section_nav
    promises[:section_nav] = SectionNavPresenter.new(
      user: current_user,
      view_context:,
      course: the_course,
      section: the_section,
      item: the_item&.value!
    )
  end

  private

  def item_available?(item)
    item_unlocked?(item) && item['published']
  end

  def item_unlocked?(item)
    start_date = item['effective_start_date']
    end_date = item['course_archived'] ? item['end_date'] : item['effective_end_date']

    (start_date.nil? || start_date <= Time.zone.now) && (end_date.nil? || end_date >= Time.zone.now)
  end
end
