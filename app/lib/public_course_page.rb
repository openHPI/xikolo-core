# frozen_string_literal: true

# For platforms running behind a portal, the primary access point for
# anonymous users should be the portal's course page. They should be
# redirected to the portal's course page (to sign up / login and enroll
# for the course).
#
# The redirect is based on the configured course URL template.
# The redirect happens when explicitly disabling the
# `public_course_page` > `enabled` (i.e. setting it to `false`).
#
# This module is also used by externally facing APIs exposing course data,
# e.g. the course feed and the MOOChub API, to expose the portal's course
# URL instead of the internal (platform) course URL.
module PublicCoursePage
  require 'addressable/template'

  class << self
    # This method defines the logic for determining the public course URL
    # based on a given template that is configured for the platform.
    def url_for(course)
      if url_template.present?
        # The CoursePresenter with its delegators requires access via
        # method call, i.e. does not support array access (like Restify resources).
        url = url_template.expand(
          course_code: course.try(:[], 'course_code') || course.course_code
        )&.to_s

        url.presence || platform_url(course)
      else
        platform_url(course)
      end
    end

    def url_template
      return unless Xikolo.config.public_course_page['url_template']

      Addressable::Template.new(Xikolo.config.public_course_page['url_template'])
    rescue TypeError
      # The template cannot be parsed for whatever reason.
      # This is fine, #url_for will handle this.
    end

    def platform_url(course)
      Rails.application.routes.url_helpers.course_url(
        course.try(:[], 'course_code') || course.course_code,
        host: Xikolo.config.base_url.site
      )
    end

    def enabled?
      Xikolo.config.public_course_page&.dig('enabled')
    end
  end

  class Redirect
    def initialize(course, user)
      @course = course
      @user = user
    end

    def redirect?
      !PublicCoursePage.enabled? && @user.anonymous? && target.present?
    end

    def target
      # Do not redirect if the URL template is not provided, i.e.
      # the course page is NOT public for anonymous users but
      # no portal redirect URL has been provided.
      return if PublicCoursePage.url_template.nil?

      PublicCoursePage.url_for(@course)
    end
  end
end
