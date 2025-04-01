# frozen_string_literal: true

module PortalAPI
  class CoursesController < BaseController
    before_action :require_authorization_header!
    before_action :require_shared_secret!
    before_action only: :index do
      allow_content_types! %w[
        application/vnd.openhpi.list+json;v=1.0
        application/vnd.openhpi.list+json;v=1.1
      ]
    end

    def index
      response.headers['Content-Type'] = 'application/vnd.openhpi.list+json;v=1.1'

      if courses.rel?(:next)
        response.link portal_courses_url(page: page + 1), rel: 'next'
      end

      if courses.rel?(:prev)
        response.link portal_courses_url(page: page - 1), rel: 'prev'
      end

      render json: {
        items: courses.map {|course| serialize_course_for_index(course) },
      }
    end

    before_action only: :show do
      allow_content_types! %w[
        application/vnd.openhpi.course+json;v=1.0
        application/vnd.openhpi.course+json;v=1.1
      ]
    end

    def show
      return head(:not_found) if private_course?

      response.headers['Content-Type'] = 'application/vnd.openhpi.course+json;v=1.1'
      response.link portal_course_url(course['id']), rel: 'self'

      render json: serialize_course_for_show(course)
    rescue Restify::NotFound
      head(:not_found)
    end

    private

    def courses
      @courses ||= Xikolo.api(:course).value!.rel(:courses)
        .get({public: true, hidden: false, exclude_external: true, latest_first: true, page:})
        .value!
    end

    def page
      @page ||= [params[:page].to_i, 1].max
    end

    def course
      @course ||= Xikolo.api(:course).value!.rel(:course).get({id: params[:id]}).value!
    end

    def private_course?
      # Don't expose external and hidden courses and those in preparation
      return true if course['status'] == 'preparation'
      return true if course['external_course_url'].present?
      return true if course['hidden']

      # TODO: Group-restricted courses should also not be exposed.

      # All other courses can be exposed
      false
    end

    def serialize_course_for_index(course)
      {url: portal_course_url(course['id'])}
    end

    def serialize_course_for_show(course)
      {
        id: course['id'],
        title: course['title'],
        abstract: course['abstract'],
        description: course['description'],
        start_date: course['start_date'],
        end_date: course['end_date'],
        language: course['lang'],
      }
    end
  end
end
