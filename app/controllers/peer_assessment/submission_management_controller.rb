# frozen_string_literal: true

class PeerAssessment::SubmissionManagementController < PeerAssessment::BaseController
  require 'uri'

  include PeerAssessment::DisplayStudentSubmissionHelper
  include PeerAssessment::RegradingHelper

  inside_course

  before_action { authorize! 'peerassessment.submission.manage' }
  before_action :load_participant, only: %i[show request_regrading]

  def index
    request_params = {
      peer_assessment_id: @assessment.id,
        include_votes: true,
        gallery_ids: 'all',
    }

    if params.key?(:user_filter)
      # Relying on the account service implementation to
      # filter for SQL injects and the like
      request_params[:user_filter] = params[:user_filter].strip
    elsif params.key?(:team_filter)
      request_params[:team_filter] = params[:team_filter].strip
    else
      request_params.merge!(
        peer_assessment_id: @assessment.id,
        include_votes: true,
        page: params[:page] || 1,
        per_page: params[:per_page] || 30,
        first: params[:first], second: params[:second], third: params[:third]
      )
      request_params[:final_only] = true if params.key?(:final_only)
      request_params[:gallery_only] = true if params.key?(:gallery_only)
    end

    Restify::Promise.new([
      pa_api.rel(:submissions).get(request_params),
      pa_api.rel(:statistics).get(peer_assessment_id: @assessment.id, concern: 'assessment_statistic'),
      pa_api.rel(:gallery_votes).get(user_id: current_user.id, peer_assessment_id: @assessment.id),
    ]) do |pager_collection, statistics, gallery_votes|
      @pager_collection = pager_collection
      @submission_presenters = @pager_collection.map do |submission|
        PeerAssessment::SubmissionPresenter.create(submission, true)
      end
      @statistic = PeerAssessment::StatisticsPresenter.create statistics
      @user_votes = gallery_votes.index_by {|vote| vote['shared_submission_id'] }
    end.value!

    @gallery_presenter = PeerAssessment::GalleryPresenter.new peer_assessment: @assessment

    Acfs.run
  end

  # Row hover popup via AJAX - TBD
  def submission_details
    Acfs.run
  end

  # This action is duplicated in the SubmissionManagementController.
  # It may be worth it to extract a reusable helper (class!) for the shared logic,
  # once this code is using direct database access.
  def request_regrading
    Acfs.on the_assessment, the_steps, the_participant do |assessment, steps, participant|
      @grading_step = steps.detect {|s| s.is_a? Xikolo::PeerAssessment::PeerGrading }

      # Check for an existing grading conflict
      @grading_conflict = Xikolo::PeerAssessment::Conflict.find_by(
        reporter: participant.user_id,
        peer_assessment_id: assessment.id,
        reason: 'grading_conflict'
      )

      submission = pa_api.rel(:submissions).get(
        peer_assessment_id: assessment.id,
        user_id: participant.user_id
      ).value!.first
      @grade = pa_api.rel(:grades).get(submission_id: submission.id).value&.first

      reviews = pa_api.rel(:reviews).get(
        step_id: @grading_step.id,
        submission_id: submission.id
      ).value || []

      @received_reviews = []
      reviews.each do |review|
        @received_reviews << PeerAssessment::ReviewPresenter.create(review)
      end
    end

    Acfs.run

    @regrading_possible = check_regrading_eligibility(@current_step, @received_reviews, @grade, @grading_conflict)

    unless @regrading_possible
      add_flash_message :error, I18n.t(:'peer_assessment.results.grading_conflict.not_eligible')
      return redirect_back fallback_location: root_path
    end

    # TODO: Remove Acfs
    @new_grading_conflict = Xikolo::PeerAssessment::Conflict.create!(
      reporter: @participant.user_id,
      reason: 'grading_conflict',
      peer_assessment_id: @assessment.id,
      comment: params[:xikolo_peer_assessment_conflict][:comment]
    )

    add_flash_message :success, I18n.t(:'peer_assessment.results.grading_conflict.success')

    redirect_back fallback_location: root_path
  end

  def show
    @available_steps = collect_available_steps @pa_id
    @available_steps_with_id = collect_available_steps_with_id @pa_id
    @available_rubrics_with_id = collect_available_rubrics_with_id @pa_id

    submission_id = UUID4.try_convert(params[:id]).to_s
    submission = pa_api.rel(:submission).get(id: submission_id, include_votes: true).value!
    @submission = PeerAssessment::SubmissionPresenter.create(submission)
    @examined_user_id = @submission.user_id

    @submission_created = DateTime.parse(submission.created_at).strftime('%d.%m.%Y %H:%M')
    @submission_gallery_opt_out = submission.gallery_opt_out
    @submission_draft = true unless submission.submitted

    @reviews_received = []
    @reviews_matrix = []

    # rubocop:disable Metrics/ParameterLists
    Restify::Promise.new([
      pa_api.rel(:gallery_votes).get(submission_id: submission.id, user_id: current_user.id),
      account_api.rel(:user).get(id: submission.user_id),
      pa_api.rel(:reviews).get(
        submission_id: submission.id,
        with_team_submissions: true,
        grading_step_only: true,
        valid_reviews_only: true
      ),
      pa_api.rel(:reviews).get(
        submission_id: submission.id,
        with_team_submissions: true,
        grading_step_only: true
      ),
      pa_api.rel(:reviews).get(user_id: submission.user_id, peer_assessment_id: @assessment.id),
      pa_api.rel(:participants).get(user_id: submission.user_id, peer_assessment_id: @pa_id),
      pa_api.rel(:steps).get(peer_assessment_id: @pa_id, type: 'Results'),
    ]) do |user_votes, user, valid_reviews, received_reviews, written_reviews, participants, result_steps|
      @user_vote = user_votes.first
      @user = user

      valid_reviews.each do |rr|
        options = collect_options(rr)
        @reviews_matrix << options
      end

      received_reviews.each do |rr|
        @reviews_received << extract_review_data(rr)
      end

      @reviews_written = written_reviews.map do |review|
        extract_review_data(review)
      end.sort_by {|k| k['step_type'] }
      @participant = participants.first
      @result_step = result_steps.first
    end.value!
    # rubocop:enable all

    @current_step ||= pa_api.rel(:steps).get(id: @participant.current_step).value!.first

    @rubric_matrix = get_matrix_values(@reviews_matrix, @available_rubrics_with_id)

    unless @submission.nil? || @submission_draft
      @submission_path = teachermode_step_path :submission, @pa_id, @examined_user_id
    end
    @training_path = teachermode_step_path :training, @pa_id, @examined_user_id
    @peer_grading_path = teachermode_step_path :peer_grading, @pa_id, @examined_user_id
    @self_assessment_path = teachermode_step_path :self_assessment, @pa_id, @examined_user_id
    if @participant.current_step == @result_step.id
      @results_path = teachermode_step_path :results, @pa_id, @examined_user_id
    end

    @submission_management_presenter = PeerAssessment::SubmissionManagementPresenter.new(
      peer_assessment: @assessment,
      submission_id:
    )
    @display_student_submission_presenter = PeerAssessment::DisplayStudentSubmissionPresenter.new(
      peer_assessment: @assessment,
      submission_id:
    )

    Acfs.run

    @regrading_possible = current_user.allowed?('peerassessment.submission.request_regrading')
    @new_grading_conflict = Xikolo::PeerAssessment::Conflict.new if @regrading_possible
  end

  # collects the points for all rubrics that have been given for a certain
  # submission by all reviewers. reviews that have been reported by the author
  # of the submission are omitted. creates a matrix reviewer => points per
  # rubric (sorted by rubrics), reason for report if any otherwise false
  #
  #     [{
  #       "reviewer1" => [
  #         {
  #           "rubric1" => points_given,
  #           "rubric2" => points_given,
  #           "rubric3" => points_given
  #         },
  #         'plagiarism']
  #      }, {
  #       "reviewer2" => [
  #         {
  #           "rubric1" => points_given,
  #           "rubric2" => points_given,
  #           "rubric3" => points_given
  #         },
  #         'false']
  #      }, ... ]
  #
  # The data is used to display a table with the review details:
  #
  #                | rubric1 | rubric2 | rubric3 | rubric4 | rubric5 |
  #     reviewer1  |    1    |    1    |    0    |     1   |    1    |
  #     reviewer2  |    2    |    0    |    1    |     3   |    2    |
  #     reviewer3  |    3    |    0    |    1    |     4   |    1    |
  #
  def get_matrix_values(reviews_matrix_raw, available_rubrics)
    reviews_matrix_raw.flat_map do |row|
      row.map do |reviewer_id, option_ids|
        reviewer = account_api.rel(:user).get(id: reviewer_id).value!
        matrix_row = {reviewer.email => []}
        option_ids.each do |option_id|
          option = pa_api.rel(:rubric_option).get(id: option_id).value!
          o_hash = {available_rubrics[option.rubric_id] => option.points}
          matrix_row[reviewer.email] << o_hash
        end
        matrix_row[reviewer.email] = matrix_row[reviewer.email].reduce({}, :update)

        if option_ids.size < available_rubrics.size
          available_rubrics.each_value do |rubric_name|
            unless matrix_row[reviewer.email].key?(rubric_name)
              matrix_row[reviewer.email][rubric_name] = 0
            end
          end
        end
        matrix_row[reviewer.email] = matrix_row[reviewer.email].sort_by {|key, _value| key }.to_h
        matrix_row
      end
    end
  end

  def collect_options(review)
    {review.user_id => review.option_ids}
  end

  def extract_review_data(review)
    {
      id: review.id,
      deadline: DateTime.parse(review.deadline).strftime('%d.%m.%Y %H:%M'),
      grade: review.grade,
      feedback_grade: review.feedback_grade.nil? ? 'none' : review.feedback_grade,
      step_type: @available_steps_with_id[review.step_id],
      conflict: review.conflict,
      suspended: review.suspended,
      accused: review.accused,
    }
  end

  def grant_attempt
    submission_id = UUID4.try_convert(params[:id]).to_s
    submission = pa_api.rel(:submission).get(id: submission_id).value!

    Acfs.run

    submission.additional_attempts += 1
    submission_request = pa_api.rel(:submission).put({
      additional_attempts: submission.additional_attempts,
    }, {
      id: submission.id,
      admin_edit: true,
    }).value!
    if submission_request.response.code.to_i == 204
      add_flash_message :success, I18n.t(:'peer_assessment.submission_management.grant_attempt_success')
    else
      add_flash_message :error, I18n.t(:'peer_assessment.submission_management.grant_attempt_error')
    end
    redirect_to peer_assessment_submission_management_path params[:peer_assessment_id], params[:id]
  end

  def rate
    Acfs.run

    if params[:existing_vote].blank?
      # Create a new vote
      submission_id = UUID4.try_convert(params[:id]).to_s
      shared_submission_id = pa_api.rel(:shared_submission).get(
        submission_id:
      ).value!.first['id']
      pa_api.rel(:gallery_votes).post(
        user_id: current_user.id,
        shared_submission_id:,
        rating: params[:rating].to_i
      ).value!
    else
      shared_submission_id = pa_api.rel(:gallery_vote).get(
        id: params[:existing_vote]
      ).value!['shared_submission_id']
      pa_api.rel(:gallery_vote).put({rating: params[:rating].to_i}, {id: params[:existing_vote]}).value!
    end

    # add shared_submission to gallery entries if checkbox is checked and the
    # element doesn't yet exist
    if params[:include_submission]
      unless @assessment.gallery_entries.include? shared_submission_id
        @assessment.gallery_entries << shared_submission_id
      end
      pa_api.rel(:peer_assessment).put({
        gallery_entries: @assessment.gallery_entries,
      }, {id: @pa_id}).value!
    # remove shared_submission from gallery entries if checkbox is not checked
    elsif @assessment.gallery_entries.include? shared_submission_id
      @assessment.gallery_entries.reject! {|el| el == shared_submission_id }
      pa_api.rel(:peer_assessment).put({
        gallery_entries: @assessment.gallery_entries,
      }, {id: @pa_id}).value!
    end

    add_flash_message :success, I18n.t(:'peer_assessment.submission_management.rating_success')
    redirect_to peer_assessment_submission_management_path
  rescue Restify::ResponseError
    add_flash_message :error, I18n.t(:'peer_assessment.submission_management.rating_error')
    redirect_to request.referer
  end

  def generate_gallery
    @submissions = @assessment.gallery_entries.each_with_object([]) do |gallery_entry, submissions|
      shared_submission = pa_api.rel(:shared_submissions).get(id: gallery_entry).value!
      submission_ids = shared_submission.map(&:submission_ids).flatten!

      submission_ids.each do |submission_id|
        submission = pa_api.rel(:submission).get(id: submission_id).value!
        submissions << PeerAssessment::SubmissionPresenter.create(submission, true)
      end
    end

    Acfs.run

    render partial: 'gallery_template', content_type: 'text/plain'
  end

  def hide_course_nav?
    true
  end
end
