# frozen_string_literal: true

class Statistic
  extend ActiveModel::Naming

  attr_reader :available_submissions, :finished_reviews, :required_reviews,
    :submitted_submissions, :reviews, :submitted_reviews, :conflicts, :nominations, :point_groups,
    :submissions_with_content

  def initialize(params)
    # Assessment for the statistic focus
    @assessment = PeerAssessment.find params[:peer_assessment_id]
    @concern = params[:concern]

    load_stats params
  end

  def load_stats(params)
    case @concern
      when 'training'             then collect_training_stats
      when 'student_training'     then collect_student_training_stats params[:user_id]
      when 'student_grading'      then collect_student_grading_stats  params[:user_id]
      when 'assessment_statistic' then collect_assessment_statistic
    end
  end

  alias reload load_stats

  private

  def collect_training_stats
    # Constant for training phase
    @required_reviews = Training.required_ta_reviews

    # Number of submitted training reviews
    @finished_reviews = @assessment.reviews.where(train_review: true, submitted: true).count

    # Number of training pool entries, which can still be graded for the train
    # process
    @available_submissions = @assessment.resource_pools.find_by(
      purpose: 'training'
    ).pool_entries.where('available_locks > 0').count
  end

  def collect_student_training_stats(user_id)
    # Using this as well in the queries prevents us from falsely retrieving peer
    # grading step reviews (if the user chooses to go back to this step)
    training_step     = @assessment.steps.detect {|step| step.is_a? Training }
    @required_reviews = training_step.required_reviews
    @finished_reviews = @assessment.reviews.where(
      train_review: false,
      submitted: true,
      user_id:,
      step_id: training_step.id
    ).count
  end

  def collect_student_grading_stats(user_id)
    # Only select non-suspended, submitted reviews
    @finished_reviews = Review.where(
      user_id:,
      step_id: @assessment.grading_step.id,
      submitted: true
    ).not_suspended.size
    @required_reviews = @assessment.grading_step.required_reviews
  end

  def collect_assessment_statistic
    @available_submissions = Submission.joins(:shared_submission).where(
      shared_submissions: {
        peer_assessment_id: @assessment.id,
      }
    ).count
    @submitted_submissions = Submission.joins(:shared_submission).where(
      shared_submissions: {
        peer_assessment_id: @assessment.id,
        submitted: true,
      }
    ).count
    @submissions_with_content = Submission.joins(:shared_submission).where(
      shared_submissions: {
        peer_assessment_id: @assessment.id,
        submitted: false,
      }
    ).where("text IS NOT NULL AND text != '' OR attachments != '{}'").count

    @reviews = Review.joins(:peer_assessment).where(
      peer_assessments: {id: @assessment.id}
    ).count
    @submitted_reviews = Review.joins(:peer_assessment).where(
      peer_assessments: {id: @assessment.id},
      submitted: true
    ).count

    @conflicts   = Conflict.where(peer_assessment_id: @assessment.id).count
    @nominations = Review.joins(:peer_assessment).where(
      peer_assessments: {id: @assessment.id},
      submitted: true,
      award: true
    ).count

    @point_groups = []

    # Submission create and submission submit point groups
    @point_groups << ['submission_create', Submission.joins(:shared_submission).reorder('').where(
      shared_submissions: {peer_assessment_id: @assessment.id}
    ).group_by_day('submissions.created_at').count.to_a]
    @point_groups << ['submission_submit', Submission.joins(:shared_submission).reorder('').where(
      shared_submissions: {
        peer_assessment_id: @assessment.id,
        submitted: true,
      }
    ).group_by_day('submissions.updated_at').count.to_a]
  end
end
