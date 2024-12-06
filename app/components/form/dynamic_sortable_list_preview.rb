# frozen_string_literal: true

module Form
  class DynamicSortableListPreview < ViewComponent::Preview
    def simple
      render Form::DynamicSortableList.new(['Item 1', 'Item 2', 'Item 3'])
    end

    # @label Dynamic with text input
    def input
      render Form::DynamicSortableList.new(['Teacher 1', 'Teacher 2'], input_id: 'teachers')
    end

    # @label Dynamic with dropdown menu
    def select
      render Form::DynamicSortableList.new(['Course 1', 'Course 2'],
        select_config: {url: 'http://localhost:3000/admin/find_courses', placeholder: 'Add Courses'})
    end
  end
end
