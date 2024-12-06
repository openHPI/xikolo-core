# frozen_string_literal: true

class Admin::CourseListPresenter
  extend Forwardable

  def initialize(courses, category)
    @courses = courses
    @category = category
  end

  include Rails.application.routes.url_helpers

  Category = Struct.new(:title, :url, :active?)
  def categories
    [
      Category.new(
        I18n.t('admin.courses.index.published'),
        admin_courses_path,
        @category == 'published'
      ),
      Category.new(
        I18n.t('admin.courses.index.preparation'),
        admin_courses_path(category: 'preparation'),
        @category == 'preparation'
      ),
    ]
  end

  def_delegator :@courses, :each

  def pagination
    RestifyPaginationCollection.new(@courses)
  end
end
