# frozen_string_literal: true

class GradesController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    if params.key?(:peer_assessment_id) && params.key?(:user_id)
      grades = Grade.for_user_in_assessment(params[:user_id], params[:peer_assessment_id])
    else
      grades = Grade.all
      if params[:submission_id].present?
        grades.where! submission_id: params[:submission_id]
      end
    end

    respond_with grades
  end

  def show
    respond_with Grade.find params[:id]
  end

  def update
    # This controller action will only be used by the administrative interfaces.
    grade = Grade.find(params[:id])
    if [true, 'true'].include? params[:is_team_grade]
      Grade.joins(submission: :shared_submission)
        .where(submissions: {shared_submission_id: grade.submission.shared_submission_id})
        .find_each do |team_grade|
          team_grade.update update_params.except(:bonus_points)
          team_grade.compute_grade(recompute: true)
        end
    else
      grade.update update_params
      grade.compute_grade(recompute: true)
    end

    respond_with grade
  end

  private

  def update_params
    params.permit :delta, :absolute, :bonus_points
  end
end
