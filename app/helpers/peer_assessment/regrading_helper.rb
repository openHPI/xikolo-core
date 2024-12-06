# frozen_string_literal: true

module PeerAssessment::RegradingHelper
  include PeerAssessment::PeerAssessmentContextHelper

  private

  # Determine whether it is possible to file a grading correction request or not
  def check_regrading_eligibility(current_step, received_reviews, grade = nil, grading_conflict = nil)
    # 1. There is no existing request
    # 2. The student actually received reviews (if not, a special no_reviews
    #    conflict will be filed automatically by the service)
    # 3. There is no applied absolute delta
    # 4. The grade is available
    # 5. Half or less of the reviewers have given the same grade, or the
    #    submission has received less than 3 reviews
    # 6. The student rated all received reviews
    current_user.allowed?('peerassessment.submission.request_regrading') ||
      current_user.instrumented? ||
      regrading_possible_for_user?(current_step, received_reviews, grade, grading_conflict)
  end

  def regrading_possible_for_user?(current_step, received_reviews, grade = nil, grading_conflict = nil)
    basic_requirements_fulfilled?(current_step, grading_conflict, received_reviews) \
    && grade_exists_and_has_not_been_regraded?(grade) \
    && all_reviews_have_been_rated?(received_reviews) \
    && no_consensus_in_reviews?(grade)
  end

  def all_reviews_have_been_rated?(received_reviews)
    # all reviews that are not suspended are graded
    received_reviews.none? {|r| !r.suspended && r.feedback_grade.nil? }
  end

  def basic_requirements_fulfilled?(current_step, grading_conflict, received_reviews)
    current_step.deadline.to_datetime.future? && grading_conflict.nil? && (received_reviews.count > 0)
  end

  def grade_exists_and_has_not_been_regraded?(grade)
    !grade.nil? && !grade.absolute && !grade.base_points.nil?
  end

  def no_consensus_in_reviews?(grade)
    grade.regradable
  end
end
