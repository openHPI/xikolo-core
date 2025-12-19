# frozen_string_literal: true

class LtiController < ApplicationController
  before_action :set_no_cache_headers
  before_action :ensure_logged_in, only: %i[tool_launch tool_return]

  skip_before_action :verify_authenticity_token, only: %i[tool_grading tool_return]
  skip_around_action :auth_middleware, only: :tool_grading

  def tool_launch
    item = Course::Item.find(UUID4(params[:id]))

    if item.submission_deadline_passed?(current_user.id)
      add_flash_message(:error, I18n.t(:'flash.error.quiz_submissions_submission_deadline_passed'))
      return redirect_to(course_item_url(params[:course_id], params[:id]))
    end

    @launch = Course::LtiLaunchPresenter.new(item, current_user)
    render 'items/lti_exercise/tool_launch', layout: 'plain'
  end

  def tool_grading
    tg = ToolGrading.new(request, course.id)

    if (err = tg.error)
      return render(plain: err, status: :unauthorized)
    end

    if tg.response_successful?
      tg.grade! # Create score for LTI submission
      tg.publish_lti_submission_event # Publish xi-lanalytics LTI submission event
    end

    render plain: tg.xml_response, content_type: 'application/xml'
  rescue ToolGrading::ValidationError
    render plain: 'Tool grading failed', status: :unprocessable_entity
  end

  def tool_return
    add_flash_message(:error, CGI.escape_html(params[:lti_errormsg])) if params[:lti_errormsg]
    add_flash_message(:notice, CGI.escape_html(params[:lti_msg])) if params[:lti_msg]
    redirect_to(course_item_url(params[:course_id], params[:id]))
  end

  private

  def auth_context
    if params[:action] == 'tool_grading'
      :root
    else
      course.context_id
    end
  end

  def course
    @course ||= Course::Course.by_identifier(params[:course_id]).take!
  end

  class ToolGrading
    require 'digest'

    MAXIMUM_SESSION_AGE = 60.minutes
    SCORE_REGEXP = /^1(\.0+)?$|^0(\.\d+)?$/

    class ValidationError < ::StandardError; end

    def initialize(request, course_id)
      @request = request
      @lti_request = IMS::LTI::OutcomeRequest.from_post_request(request)
      @course_id = course_id
    end

    def error
      return 'Grading ID required' if id.blank?
      return 'Authorization_failed' unless authorized?

      'Session_expired' if session_expired?
    end

    def response_successful?
      lti_response.success?
    end

    def xml_response
      lti_response.generate_response_xml
    end

    def grade!
      @grade ||= gradebook.submit!(score: score&.to_f, nonce:).tap do |grade|
        raise ValidationError if grade.errors.any?
      end
    end

    def publish_lti_submission_event
      context = {
        course_id: @course_id,
        score: score&.to_f,
        provider_name: provider.name,
        provider_start_url: provider.domain,
        # browser's user agent is not available, because the request is sent by the backend
        # user_agent: request.user_agent,
        user_ip: @request.remote_ip,
      }

      Msgr.publish({
        user: {uuid: gradebook.user_id},
        verb: {type: 'SUBMITTED_LTI_V2'},
        resource: {uuid: gradebook.lti_exercise_id, type: 'lti'},
        timestamp: nil,
        with_result: {},
        in_context: context,
      }.as_json, to: 'xikolo.web.exp_event.create')
    end

    private

    def gradebook
      @gradebook ||= Lti::Gradebook.find(id)
    end

    def authorized?
      consumer.valid_request? @request
    end

    def session_expired?
      Time.now.utc.to_i - consumer.request_oauth_timestamp.to_i > MAXIMUM_SESSION_AGE
    end

    def id
      @lti_request.lis_result_sourcedid
    end

    def score
      @lti_request.score&.value
    end

    def provider
      @provider ||= gradebook.exercise.provider
    end

    def consumer
      @consumer ||= IMS::LTI::ToolConsumer.new(
        provider.consumer_key,
        provider.shared_secret
      )
    end

    def nonce
      Digest::MD5.hexdigest("#{consumer.request_oauth_nonce}#{consumer.request_oauth_timestamp.to_i}")
    end

    def lti_response
      return @lti_response if @lti_response.present?

      @lti_response = IMS::LTI::OutcomeResponse.new
      @lti_response.message_ref_identifier = @lti_request.message_identifier
      @lti_response.operation = @lti_request.operation
      @lti_response.severity = 'status'

      unless @lti_request.replace_request?
        @lti_response.code_major = 'unsupported'
        return @lti_response
      end

      unless SCORE_REGEXP.match? score
        @lti_response.code_major = 'failure'
        return @lti_response
      end

      @lti_response.code_major = 'success'
      @lti_response
    end
  end
end
