# frozen_string_literal: true

module Course
  class NavigationDrawer < ApplicationComponent
    renders_one :main_content
    renders_one :overview_link
    renders_one :course_progress
    renders_one :navigation, ->(component:) { component }
  end
end
