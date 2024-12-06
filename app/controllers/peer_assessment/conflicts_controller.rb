# frozen_string_literal: true

class PeerAssessment::ConflictsController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper
  include PeerAssessment::ReviewHelper
  include PeerAssessment::SubmissionHelper
  include PeerAssessment::DisplayStudentSubmissionHelper
  include PeerAssessment::PermissionsHelper

  inside_course

  before_action { authorize! 'peerassessment.conflicts.manage' }

  before_action :load_assessment

  def index
    request_params = {
      peer_assessment_id: @assessment['id'],
      per_page: 30,
      page: params[:page] || 1,
      open: open_param,
      reason: params[:reason],
    }

    if params.key?(:subject)
      request_params[:conflict_subject_type] = params[:subject].capitalize
    end

    if params.key?(:user_filter)
      request_params[:user_filter] = params[:user_filter].strip
    end

    @conflicts = pa_api.rel(:conflicts).get(request_params).value!
    @conflicts.each do |conflict|
      conflict['created_at'] = DateTime.parse(conflict['created_at'])
      user_objects! conflict
    end

    Acfs.run
  end

  def show
    conflict_id = UUID4.try_convert(params[:id]).to_s
    @conflict = pa_api.rel(:conflict).get(id: conflict_id).value!
    @conflict['created_at'] = DateTime.parse(@conflict['created_at'])
    user_objects! @conflict
    # Determine what to render, collect resources accordingly
    case @conflict['conflict_subject_type']
      when 'Review'
        collect_review_resources
        submission = pa_api.rel(:submissions).get(
          user_id: @conflict['reporter'],
          peer_assessment_id: @assessment['id']
        ).value!.first
      when 'Submission'
        collect_submission_resources
        submission = pa_api.rel(:submissions).get(
          user_id: @conflict['accused'],
          peer_assessment_id: @assessment['id']
        ).value!.first
      else
        # Switch over the reason if the subject is empty
        case @conflict['reason']
          when 'grading_conflict'
            collect_grading_conflict_resources
          when 'no_reviews'
            collect_no_reviews_resources
        end
        submission = pa_api.rel(:submissions).get(
          user_id: @conflict['reporter'],
          peer_assessment_id: @assessment['id']
        ).value!.first
    end

    unless submission.nil?
      @path_to_submission = path_to_submission(
        @assessment['id'],
        submission['id']
      )
    end
    load_notes @conflict['id']

    @is_team_grade = @assessment['is_team_assessment'] &&
                     @conflict['conflict_subject_type'] != 'Review'

    @available_steps = collect_available_steps @pa_id

    @submission_path = teachermode_step_path :submission, @pa_id, @submission.user_id unless @submission.nil?
    if @available_steps.include? 'Training'
      @training_path = teachermode_step_path :training, @pa_id, @submission.user_id
    end
    @peer_grading_path = teachermode_step_path :peer_grading, @pa_id, @submission.user_id
    @self_assessment_path = teachermode_step_path :self_assessment, @pa_id, @submission.user_id
    @results_path = teachermode_step_path :results, @pa_id, @submission.user_id if @current_step == 'Results'

    Acfs.run

    # To ease the navigation -> users go back to the page they came from
    @page = params[:page]
  end

  def path_to_submission(pa_id, submission_id)
    peer_assessment_submission_management_path(
      short_uuid(pa_id),
      short_uuid(submission_id)
    )
  end

  def reconcile
    @conflict = pa_api.rel(:conflict).get(id: UUID4.try_convert(params[:id]).to_s).value!
    if @conflict['reason'] == 'no_reviews'
      submission = pa_api.rel(:submissions).get(
        user_id: @conflict['reporter'],
        peer_assessment_id: @assessment.id
      ).value!.first
      @review = pa_api.rel(:reviews).get(
        as_ta_grading: true,
        submission_id: submission['id'],
        user_id: current_user.id
      ).value!.first
    end

    if @conflict['reporter'].present?
      @reporter_grade = pa_api.rel(:grades).get(
        peer_assessment_id: @assessment['id'],
        user_id: @conflict['reporter']
      ).value!.first
    end

    if @conflict['accused'].present?
      @accused_grade = pa_api.rel(:grades).get(
        peer_assessment_id: @assessment['id'],
        user_id: @conflict['accused']
      ).value!.first
    end

    Acfs.run

    if @conflict['reason'] == 'no_reviews'
      handle_no_reviews_reconciliation
    else
      # the reporter is always blamed/praised individually
      # do not blame team members for bad reviews
      # only exception: regrading should be applied on reporting team
      apply_on_reporting_team = @conflict['reason'] == 'grading_conflict'
      apply_on_accused_team = @assessment['is_team_assessment'] &&
                              @conflict['conflict_subject_type'] != 'Review'
      change_grade(@reporter_grade, is_team_grade: apply_on_reporting_team) if @reporter_grade
      change_grade(@accused_grade, is_team_grade: apply_on_accused_team) if @accused_grade
    end

    request = pa_api.rel(:conflict).put({open: false}, {id: @conflict['id']}).value!
    if request.response.code == 204
      add_flash_message :success, I18n.t(:'peer_assessment.conflict.reconciliation_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.conflict.reconciliation_error')
    end

    redirect_to peer_assessment_conflicts_path
  end

  private

  def user_objects!(conflict)
    if conflict['reporter'].present?
      conflict['reporter_object'] = account_api.rel(:user).get(id: conflict['reporter']).value!
    end

    if conflict['accused'].present?
      conflict['accused_object'] = account_api.rel(:user).get(id: conflict['accused']).value!
    end
    if conflict['accused_team_members'].present?
      conflict['accused_team_member_objects'] = []
      conflict['accused_team_members'].each do |member|
        conflict['accused_team_member_objects'] << account_api.rel(:user).get(id: member).value!
      end
    end
  end

  def load_notes(subject_id)
    @notes = pa_api.rel(:notes).get(subject_id:).value!
    @notes.map do |note|
      account_api.rel(:user).get(id: note.user_id).then do |user|
        note['author'] = user
      end
    end.each(&:value!)

    @new_note = PeerAssessment::NoteForm.new
  end

  def collect_review_resources
    # Filed against a review, get the review and the submission, as well as the grades

    Restify::Promise.new(
      pa_api.rel(:review).get(id: @conflict['conflict_subject_id']),
      pa_api.rel(:rubrics).get(peer_assessment_id: @assessment.id)
    ) do |review, rubrics|
      @review = PeerAssessment::ReviewPresenter.create review
      @rubric_presenters = build_rubric_presenters rubrics
    end.value!

    collect_grades!
    @template = 'peer_assessment/conflicts/subjects/review'
    submission = submission_by_id @review.submission_id
    @submission = PeerAssessment::SubmissionPresenter.create submission
  end

  def collect_submission_resources
    # Filed against a submission, get the submission, its files, and associated grades
    collect_grades!
    @template = 'peer_assessment/conflicts/subjects/submission'

    submission = submission_by_id @conflict['conflict_subject_id']
    @submission = PeerAssessment::SubmissionPresenter.create submission
  end

  def collect_grading_conflict_resources
    # Get the submission and all received reviews, as well as the grade

    steps = nil
    Restify::Promise.new(
      pa_api.rel(:submissions).get(peer_assessment_id: @assessment.id, user_id: @conflict['reporter']),
      pa_api.rel(:rubrics).get(peer_assessment_id: @assessment.id),
      pa_api.rel(:steps).get(peer_assessment_id: @assessment.id)
    ) do |submissions, rubrics, steps_from_service|
      @submission = PeerAssessment::SubmissionPresenter.create submissions.first
      @rubric_presenters = build_rubric_presenters rubrics
      steps = steps_from_service
    end.value!

    @received_reviews = []
    reviews = pa_api.rel(:reviews).get(
      submission_id: @submission.id,
      step_id: steps.detect {|s| s.type == 'Xikolo::PeerAssessment::AssignmentSubmission' }.id
    ).value!
    @reviews_to_participants = {}
    reviews.map do |review|
      pa_api.rel(:participants).get(
        user_id: review['user_id'],
        peer_assessment_id: @assessment.id
      ).then do |participant|
        presenter = PeerAssessment::ReviewPresenter.create(review)
        @received_reviews << presenter
        @reviews_to_participants[presenter.id] = participant
      end
    end.each(&:value!)
    @reporter_grade = pa_api.rel(:grade).get(id: @submission.grade).value!
    @template = 'peer_assessment/conflicts/subjects/grading_conflict'
  end

  def collect_no_reviews_resources
    @template = 'peer_assessment/conflicts/subjects/no_reviews'

    Restify::Promise.new(
      pa_api.rel(:rubrics).get(peer_assessment_id: @assessment.id),
      pa_api.rel(:submissions).get(peer_assessment_id: @assessment.id, user_id: @conflict['reporter'])
    ) do |rubrics, submission|
      @rubric_presenters = build_rubric_presenters rubrics
      @submission = PeerAssessment::SubmissionPresenter.create submission.first
    end.value!

    review = pa_api.rel(:reviews).get(
      as_ta_grading: true,
      submission_id: @submission.id,
      user_id: current_user.id
    ).value!.first
    @review = PeerAssessment::ReviewPresenter.create(review)

    @form_presenter = PeerAssessment::ReviewFormPresenter.create(@assessment, @review, 'ta_review')
    @form_presenter.conflict_id     = @conflict.id
    @form_presenter.small_buttons   = true
    @form_presenter.small_headlines = true
    @form_presenter.enable_awards   = true
    @form_presenter.confirm_title   = I18n.t(:'peer_assessment.conflict.no_review_submit_title')
    @form_presenter.confirm_message = I18n.t(:'peer_assessment.conflict.no_review_submit_message')
    @form_presenter.submit_button_text = I18n.t(:'peer_assessment.conflict.reconcile_button')
  end

  # Build a (rudimentary) string representation of the changes made by the mediator for a grade
  def changes_str(grade, role)
    StringIO.new.tap do |str|
      str << " #{role}:"
      str << ' ('
      str << I18n.t(:'peer_assessment.conflict.delta') << ': ' << params['grade'][grade.id]['delta']['new'] << '; '
      str << I18n.t(:'peer_assessment.conflict.absolute') << ': ' << params['grade'][grade.id]['absolute'].key?(:new)
      str << ')'
    end.string
  end

  def collect_grades!
    Restify::Promise.new(
      pa_api.rel(:grades).get(peer_assessment_id: @assessment['id'], user_id: @conflict['reporter']),
      pa_api.rel(:grades).get(peer_assessment_id: @assessment['id'], user_id: @conflict['accused'])
    ) do |reporter_grades, accused_grades|
      @reporter_grade = reporter_grades.first
      @accused_grade  = accused_grades.first
    end.value!
  end

  def change_grade(grade, is_team_grade: false)
    if grade && params['grade'].key?(grade.id)
      abs_initial  = params['grade'][grade.id]['absolute']['initial']
      delta_inital = params['grade'][grade.id]['delta']['initial']

      # Compare initial values with values for the service to determine
      # if something changed in the meantime.
      if (abs_initial != grade.absolute.to_s) || (delta_inital.to_d != grade.delta.to_d)
        # If there were changes, abort and redirect the user to the
        # conflict page to review the changes
        changes_string = StringIO.new.tap do |str|
          str << changes_str(grade, I18n.t(:'peer_assessment.conflict.reporter')) if @reporter_grade
          str << ' '
          str << changes_str(@accused_grade, I18n.t(:'peer_assessment.conflict.accused_student')) if @accused_grade
        end.string
        add_flash_message :error, I18n.t(:'peer_assessment.conflict.conflicting_changes', changes: changes_string)
        raise Status::Redirect.new 'Concurrent changes', peer_assessment_conflict_path(
          short_uuid(@assessment.id),
          short_uuid(@conflict.id)
        )
      end

      abs_new   = params['grade'][grade.id]['absolute'].fetch(:new, false)
      delta_new = params['grade'][grade.id]['delta']['new'].try(:to_f) || 0.0

      pa_api.rel(:grade).put({
        absolute: abs_new,
        delta: delta_new,
        is_team_grade:,
      }, {id: grade.id}).value!
    end
  end

  def handle_no_reviews_reconciliation
    text = params[:xikolo_peer_assessment_review][:text]
    award = params[:xikolo_peer_assessment_review][:award]

    pa_api.rel(:review).put({
      optionIDs: get_selected_options,
      text:,
      award:,
      submitted: true,
    }, {id: @review.id}).value!
  end

  def open_param
    case params[:state]
      when 'true'
        true
      when 'false'
        false
    end
  end
end
