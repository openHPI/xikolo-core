# frozen_string_literal: true

module Course
  class BottomNavigationPreview < ViewComponent::Preview
    include ActionView::Helpers::UrlHelper

    def default
      render ::Course::BottomNavigation.new(course_id: course.id,
        prev_item_id: item(course.items.first.id).id,
        next_item_id: item(course.items.third.id).id)
    end

    def next_only
      render ::Course::BottomNavigation.new(course_id: course.id,
        prev_item_id: nil,
        next_item_id: item(course.items.second.id).id)
    end

    def prev_only
      render ::Course::BottomNavigation.new(course_id: course.id,
        prev_item_id: item(course.items.second_to_last.id).id,
        next_item_id: nil)
    end

    private

    def course
      return @course if defined?(@course)

      @course = Course.find_by(course_code: 'content-ab')
    end

    MockQuizItemPresenter = Struct.new(:id, :course_id, :section_id)
    private_constant :MockQuizItemPresenter

    def item(id)
      MockQuizItemPresenter.new(
        id:,
        course_id: course.id,
        section_id: course.sections.first.id
      )
    end
  end
end
