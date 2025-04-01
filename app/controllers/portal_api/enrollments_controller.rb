# frozen_string_literal: true

module PortalAPI
  class EnrollmentsController < BaseController
    before_action :require_authorization_header!
    before_action :require_shared_secret!
    before_action do
      allow_content_types! ALLOWED_CONTENT_TYPES[action_name.to_sym]
    end

    ALLOWED_CONTENT_TYPES = {
      index: %w[application/vnd.openhpi.enrollments+json;v=1.0],
      create: %w[application/vnd.openhpi.enrollment+json;v=1.0],
    }.freeze

    def index
      if params[:user_id].blank?
        return problem_details(
          'parameter_missing',
          'The user_id cannot be blank.',
          status: :unprocessable_entity
        )
      end

      response.headers['Content-Type'] = 'application/vnd.openhpi.enrollments+json;v=1.0'

      render json: enrollments.map {|enrollment| serialize_enrollment(enrollment) }
    rescue CourseNotFound, UserNotFound
      problem_details(
        'course_or_user_not_found',
        'Course or user not found.',
        status: :not_found
      )
    end

    def create
      if params[:user_id].blank? || params[:course_id].blank?
        return problem_details(
          'parameter_missing',
          'The user_id and course_id cannot be blank.',
          status: :unprocessable_entity
        )
      end

      if enrollments.any?
        return problem_details(
          'enrollment_already_present',
          'An enrollment for this user and course already exists.',
          status: :conflict
        )
      end

      enrollment = course_api.rel(:enrollments)
        .post({user_id: authorization['user_id'], course_id: params[:course_id]})
        .value!

      response.headers['Content-Type'] = 'application/vnd.openhpi.enrollment+json;v=1.0'
      render(json: enrollment.slice('id', 'course_id').merge('user_id' => authorization['uid']), status: :created)
    rescue Restify::UnprocessableEntity
      problem_details(
        'internal_server_error',
        'Internal server error, please try again later.',
        status: :internal_server_error
      )
    rescue CourseNotFound, UserNotFound
      problem_details(
        'course_or_user_not_found',
        'Course or user not found.',
        status: :not_found
      )
    end

    private

    def enrollments
      raise UserNotFound if authorization.blank?

      course_api.rel(:enrollments).get(
        {
          user_id: authorization['user_id'],
          course_id: params[:course_id].presence,
          learning_evaluation: true,
        }.compact
      ).value!
    rescue Restify::NotFound
      # If the user is unknown, the call for `authorization` will fail.
      # Therefore, it can be assumed that the course is unknown.
      raise CourseNotFound
    end

    def serialize_enrollment(enrollment)
      enrollment.slice(
        'id',
        'course_id',
        'created_at',
        'completed',
        'deleted'
      ).merge(
        'achievements' => enrollment['certificates']
      )
    end

    def authorization
      @authorization ||= account_api.rel(:authorizations).get({uid: params[:user_id]}).value!.first
    end

    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end
  end

  class CourseNotFound < StandardError; end
  class UserNotFound < StandardError; end
end
