# frozen_string_literal: true

module Course
  class CourseVisualPreview < ViewComponent::Preview
    def with_image_url
      render ::Course::CourseVisual.new('https://picsum.photos/300/150', width: 300, alt_text: 'Placeholder image!')
    end

    def without_image_url
      render ::Course::CourseVisual.new(nil, width: 300, alt_text: 'Default course image')
    end
  end
end
