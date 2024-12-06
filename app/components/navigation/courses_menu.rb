# frozen_string_literal: true

module Navigation
  class CoursesMenu < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    private

    def render?
      @user.feature?('course_list')
    end

    def courses
      Rails.cache.fetch(
        'nav/courses_megamenu',
        expires_in: 30.minutes
      ) do
        load_courses
      end
    end

    def load_courses
      Catalog::Course.released.for_global_list.for_guests.then do |courses|
        {
          current: courses.current.limit(5),
          upcoming: courses.upcoming.limit(5),
          archive: courses.self_paced.limit(5),
        }.delete_if {|_, crs| crs.load.empty? }.transform_values do |crs|
          crs.pluck(:course_code, :title).map {|c| {'course_code' => c[0], 'title' => c[1]} }
        end
      end
    end

    def aria_current
      return unless @active

      'page'
    end

    def active_class
      'navigation-item__main--active' if active?
    end

    def active?
      helpers.controller_path == 'home/courses' &&
        helpers.controller.action_name == 'index'
    end
  end
end
