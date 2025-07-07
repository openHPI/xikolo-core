# frozen_string_literal: true

class CourseNav < MenuWithPermissions
  # Learnings
  item 'courses.nav.sections', 'lamp-desk',
    active: lambda {|request|
      controller_name = request.filtered_parameters['controller']
      %w[items quiz_submission].include?(controller_name)
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

  # Certificates
  item 'courses.nav.certificates', 'medal',
    route: :course_certificates

  # Course Details
  item 'courses.nav.info', 'circle-info',
    route: :course

  # Documents
  item 'courses.nav.knowledge_documents', 'file-lines',
    if: ->(_user, _course) { Xikolo.config.beta_features['documents'] },
    route: :course_documents

  # Announcements
  item 'courses.nav.announcements', 'satellite-dish',
    active: lambda {|request|
      controller_name = request.filtered_parameters['controller']
      %w[announcements course/announcements].include? controller_name
    },
    route: :course_announcements

  # Quiz Recap
  item 'learn.title', 'lightbulb-on',
    if: ->(user, course) { user.feature?('quiz_recap') && course.was_available? }, # FIXME: do not use this method
    route: ->(course) { learn_path(course_id: course.id) }
end
