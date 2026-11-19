# frozen_string_literal: true

module ItemContextHelper
  def self.included(base_controller)
    # for some reason some other module seems to want to include this
    return unless base_controller.respond_to? :before_action

    base_controller.helper_method :course_item_bottom_bar

    # disabled when_course_loaded would be called to early
    # (would try to access user):
    class << base_controller
      def inside_item(**)
        layout('course_area_two_cols', **)
        before_action(:load_section_nav, **)
        before_action(:create_item_presenter!, **)
        before_action(:check_course_path, **)
      end
    end
  end

  private

  def course_item_bottom_bar
    current_item = CourseService::Item.find(item['id'])
    navigation_context = {
      user_id: current_user.id,
      preview: current_user.allowed?('course.content.access'),
    }

    previous_item = current_item.previous_item(**navigation_context)
    next_item = current_item.next_item(**navigation_context)
    navigation = Course::BottomNavigation.new(
      previous_link: course_item_navigation_link(
        previous_item || current_item.previous_section_item(**navigation_context), section: previous_item.nil?
      ),
      next_link: course_item_navigation_link(
        next_item || current_item.next_section_item(**navigation_context), section: next_item.nil?
      )
    )

    Course::BottomBar.new.tap { it.with_navigation(component: navigation) }
  end

  def course_item_navigation_link(item, section: false)
    return if item.nil?

    {
      url: course_item_path(item.course_id, item.id, anchor: 'course-item-header'),
      title: item.title,
      icon: Course::Item::Icon.from_resource(item).icon_class,
      section:,
    }
  end

  def check_course_path
    # Ensure that the requested item belongs to the given course
    course = the_course
    if the_section.value!['course_id'] != course.id
      raise Status::NotFound
    end
  end

  def create_item_presenter!
    course = the_course
    presenter_class = ItemPresenter.lookup(item)
    @item_presenter = presenter_class.build item, course, current_user, params:
  end

  def create_visit!
    return if current_user.masqueraded? || !current_user.authenticated?
    return if request.headers['X-Sec-Purpose'].to_s.include?('prefetch')
    return if @item_presenter.required_items.present?

    visit = CourseService::Visit.create_or_find_by!(user_id: current_user.id, item_id: item['id'])
    visit.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def item
    @item ||= the_item.value!
  rescue Restify::NotFound
    # This will redirect to the last visited item or to the first public or to the course info
    raise Status::Redirect.new 'Item not available', course_resume_path(the_course.id)
  end
end
