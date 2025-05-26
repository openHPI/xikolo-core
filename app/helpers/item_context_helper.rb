# frozen_string_literal: true

module ItemContextHelper
  def self.included(base_controller)
    # for some reason some other module seems to want to include this
    return unless base_controller.respond_to? :before_action

    # disabled when_course_loaded would be called to early
    # (would try to access user):
    class << base_controller
      def inside_item(**)
        layout('course_area_two_cols', **)
        before_action(:load_section_nav, **)
        before_action(:create_position_presenter!, **)
        before_action(:create_item_presenter!, **)
        before_action(:check_course_path, **)
      end
    end
  end

  private

  def check_course_path
    # Ensure that the requested item belongs to the given course
    Acfs.on the_course do |course|
      if the_section.value!['course_id'] != course.id
        raise Status::NotFound
      end
    end
  end

  def create_position_presenter!
    Acfs.on the_course do |course|
      @inner_course_position = Course::PositionPresenter.build item, course, current_user
    end
  end

  def create_item_presenter!
    Acfs.on the_course do |course|
      presenter_class = ItemPresenter.lookup(item)
      @item_presenter = presenter_class.build item, course, current_user, params:
    end
  end

  def create_visit!
    return if current_user.masqueraded? || !current_user.authenticated?
    return if @in_app || @item_presenter.required_items.present?

    Xikolo::Course::Visit.create user_id: current_user.id, item_id: item['id']
  end

  def item
    @item ||= the_item.value!
  rescue Restify::NotFound
    # This will redirect to the last visited item or to the first public or to the course info
    raise Status::Redirect.new 'Item not available', course_resume_path(the_course.id)
  end
end
