# frozen_string_literal: true

class CourseNav < MenuWithPermissions
  # Learnings
  item 'courses.nav.sections', 'lamp-desk',
    active: lambda {|request|
      controller_name = request.filtered_parameters['controller']
      %w[items quiz_submission course/syllabus].include?(controller_name)
    },
    route: :course_resume

  # Pinboard
  item 'courses.nav.discussions', 'comments',
    if: ->(_user, course) { course.pinboard_enabled },
    active: lambda {|request|
      controller_name = request.filtered_parameters['controller']
      pinboard_controller = %w[pinboard question answer pinboard_comment].include? controller_name

      pinboard_controller
    },
    route: :course_pinboard_index

  # Progress
  item 'courses.nav.progress', 'chart-mixed',
    route: :course_progress

  # Course Details
  item 'courses.nav.info', 'circle-info',
    route: :course

  # Announcements
  item 'courses.nav.announcements', 'satellite-dish',
    active: lambda {|request|
      controller_name = request.filtered_parameters['controller']
      %w[announcements course/announcements].include? controller_name
    },
    route: :course_announcements

  # Quiz Recap
  item 'learn.title', 'lightbulb-on',
    if: ->(_user, course) { course.was_available? }, # FIXME: do not use this method
    route: ->(course) { recap_path(course_id: course.id) }
end
