# frozen_string_literal: true

class SubmissionsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    # Check if the gallery votes should be included
    if params.key? :include_votes
      decoration_context[:include_votes] = params[:include_votes]
    end

    # Search by user name or mail
    if params.key? :user_filter
      users = Xikolo.api(:account).value.rel(:users).get(query: params[:user_filter]).value!
      submissions = Submission
        .joins(:shared_submission)
        .includes(:grade, shared_submission: :files)
        .where user_id: users.pluck('id'), shared_submissions: {peer_assessment_id: params[:peer_assessment_id]}
    else
      # Order params are passed as first, second, and third
      submissions = filter_records
    end

    if params[:peer_assessment_id] && assessment.is_team_assessment
      decoration_context[:team_names] = team_names = team_names(assessment.course_id)

      if params.key? :team_filter
        submissions = submissions.select {|submission| team_names[submission[:user_id]] == params[:team_filter] }
      end
    end

    respond_with submissions
  end

  def show
    if params.key? :include_votes
      decoration_context[:include_votes] = params[:include_votes]
    end

    respond_with Submission.find_by! submissions_params
  end

  def create
    shared_submission = SharedSubmission.create shared_submission_create_params
    submission = Submission.new submission_create_params.merge(shared_submission_id: shared_submission.id)
    submission.save

    respond_with submission
  end

  def update
    submission = Submission.find params[:id]
    do_validate = false

    # all of the parameters used here apply to the shared_submission
    if params[:admin_edit] == 'true'
      submission.assign_attributes(submission_admin_update_params)

    elsif params[:additional_attempt_update] == 'true'
      submission.shared_submission.assign_attributes shared_submission_update_params
      submission.shared_submission.additional_attempts = submission.additional_attempts - 1

    elsif params[:additional_attempt_file_update] != 'true'
      submission.shared_submission.assign_attributes shared_submission_update_params
      do_validate = true
    end

    if (params[:reset] && (params[:reset] == 'true')) || !do_validate
      submission.save! validate: false
      submission.shared_submission.save! validate: false
    else
      submission.save!
      submission.shared_submission.save!
    end

    respond_with submission
  rescue ActiveRecord::RecordInvalid
    # validations failed
    errors = submission.errors.messages.merge(submission.shared_submission.errors.messages)
    render status: :bad_request, json: errors
  end

  ### Decorator methods ###

  def decorate(res)
    # Explicitly decorate results when the team filter is applied (Ruby-side filtering, yuck!)
    if res.is_a? Array
      SubmissionDecorator.decorate_collection res, context: decoration_context
    else
      res.decorate context: decoration_context
    end
  end

  def decoration_context
    @decoration_context ||= {}
  end

  private

  def assessment
    @assessment ||= PeerAssessment.find(params[:peer_assessment_id])
  end

  def team_names(course_id)
    teams = {}
    Xikolo.paginate(
      Xikolo.api(:collabspace).value!.rel(:memberships).get(status: 'admin',
        kind: 'team',
        course_id:)
    ) do |membership|
      teams[membership['user_id']] = membership['collab_space_name']
    end
    teams
  end

  def shared_submission_create_params
    params.permit :id, :peer_assessment_id, :submitted, :disallowed_sample, :text, :gallery_opt_out
  end

  def submissions_params
    params.permit :id, :user_id
  end

  def shared_submissions_params
    params.permit :peer_assessment_id, :gallery_opt_out, :submitted
  end

  def submission_create_params
    params.permit :id, :user_id, :shared_submission_id
  end

  def shared_submission_update_params
    params.permit :submitted, :disallowed_sample, :text, :gallery_opt_out
  end

  def submission_admin_update_params
    params.permit :submitted, :disallowed_sample, :text, :gallery_opt_out, :additional_attempts
  end

  def filter_records
    # Used to generate a dynamic query, which hones all sortation criteria
    clauses = {
      joins: [],
        where: [],
        group_by: [],
        order_by: [],
    }

    if params.values.intersect?(%w[nominations avg_rating points])
      clauses[:where] << {shared_submissions: {peer_assessment_id: assessment.id, gallery_opt_out: false}}

      %w[first second third]
        .map {|k| params[k] }
        .compact_blank.uniq # Remove missing ones and duplicates
        .each do |filter|
        send(:"add_#{filter}_clauses", clauses)
      end

      clauses[:group_by] << 'submissions.id'
      # always group together team members
      clauses[:order_by] << 'submissions.shared_submission_id'
    else
      clauses[:where] << submissions_params.to_h

      unless shared_submissions_params.to_h.empty?
        clauses[:where] << {shared_submissions: shared_submissions_params.to_h}
      end

      clauses[:order_by] << 'shared_submissions.created_at DESC'
    end

    if params[:peer_assessment_id] && params[:gallery_only]
      clauses[:where] << {shared_submission_id: assessment.gallery_entries}
    end

    # Check if 'only final' filter is applied
    if params[:final_only]
      clauses[:where] << {shared_submissions: {submitted: true}}
    end

    build_query(clauses)
  end

  def build_query(clauses)
    # Starting clause is always the same
    submissions = Submission.unscoped.joins(:shared_submission)

    # build query by chaining .joins, .where, .group and .order
    submissions = clauses[:joins].reduce(submissions, :joins)
    submissions = clauses[:where].reduce(submissions, :where)
    submissions = submissions.group(clauses[:group_by]) if clauses[:group_by].any?
    clauses[:order_by].reduce(submissions, :order)
  end

  ### Composite query functions ###

  # rubocop:disable Layout/LineLength
  def add_nominations_clauses(clauses)
    clauses[:joins] << Arel.sql('LEFT JOIN submissions team_submission ON "shared_submissions".id = team_submission.shared_submission_id')
    clauses[:joins] << Arel.sql('LEFT JOIN reviews ON "reviews".submission_id = team_submission.id AND reviews.award = TRUE')
    clauses[:where] << Arel.sql("(reviews.submitted = TRUE OR reviews.submitted IS NULL) AND (reviews.step_id = '#{assessment.grading_step.id}' OR reviews.step_id IS NULL)")
    clauses[:order_by] << Arel.sql('count(reviews.id) DESC NULLS LAST')
  end
  # rubocop:enable Layout/LineLength

  def add_points_clauses(clauses)
    clauses[:joins] << Arel.sql('LEFT JOIN "grades" ON "grades"."submission_id" = "submissions"."id"')
    clauses[:group_by] << Arel.sql('"grades".base_points')
    clauses[:order_by] << Arel.sql('"grades".base_points DESC NULLS LAST')
  end

  # rubocop:disable Layout/LineLength
  def add_avg_rating_clauses(clauses)
    clauses[:joins] << Arel.sql('LEFT JOIN "gallery_votes" ON "shared_submissions"."id" = "gallery_votes"."shared_submission_id"')
    clauses[:order_by] << Arel.sql('AVG("gallery_votes".rating) DESC NULLS LAST')
  end
  # rubocop:enable Layout/LineLength
end
