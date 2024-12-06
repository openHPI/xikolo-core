# frozen_string_literal: true

class ReviewsController < ApplicationController
  include ReviewHelper

  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    reviews = if params[:as_train_sample]
                # TA requested a training sample to grade
                retrieve_submission_as_sample(params[:peer_assessment_id], params[:user_id])
              elsif params[:as_student_training]
                # Student requested a training submission to grade
                retrieve_student_training_sample(params[:peer_assessment_id], params[:user_id])
              elsif params[:as_peer_grading]
                # Student requested a submission to grade
                retrieve_grading_review(params[:peer_assessment_id], params[:user_id])
              elsif params[:as_self_assessment]
                get_self_assessment(params[:peer_assessment_id], params[:user_id])
              elsif params[:as_ta_grading]
                get_ta_review(params[:user_id], params[:submission_id])
              elsif params[:as_team_evaluation]
                get_team_evaluation_reviews(params[:peer_assessment_id], params[:user_id])
              end

    if reviews
      respond_with reviews.map(&:decorate)
      return
    end

    # Filter based on peer assessment id if requested (no direct assoc in the database)
    if params.key?(:peer_assessment_id)
      reviews = Review.joins(:peer_assessment).where(peer_assessments: {id: params[:peer_assessment_id]})
    elsif params[:review_id]
      reviews = Review.where(id: params[:review_id])
    elsif params.key?(:submission_id) && params[:with_team_submissions]
      # Get all submissions (including those from the team members if there are any)
      submissions = Submission.find(params[:submission_id]).team_submissions

      # Get all reviews for the submission([s] in case of a TPA)
      reviews = Review.where(submission_id: submissions.select(:id))
      params.delete :submission_id

      # If only reviews from the grading step are required, get only those and skip training / self-assessment reviews
      reviews = reviews.where(step_id: submissions.first.peer_assessment.grading_step.id) if params[:grading_step_only]

      # If only valid reviews are required, reject reviews that report a submission or were reported by the submitter
      reviews = reviews.accounted if params[:valid_reviews_only]
    else
      reviews = Review.all
    end

    reviews = reviews.where(index_params)
    respond_with reviews
  end
  # rubocop:enable all

  def show
    respond_with Review.find_by! show_params
  end

  def update
    review = Review.find params[:id]

    # Handle deadline extension
    if params[:extended].present? && !review.extended
      # Only handle the extension, nothing else will be updated
      review.extend_deadline
      return respond_with review
    end

    unless params[:feedback_grade].nil?
      # User wants to grade the review, only set the rating and ignore other checks
      review.feedback_grade = params[:feedback_grade]
      review.save validate: false
      return respond_with review
    end

    review.assign_attributes update_params
    review.optionIDs_will_change!
    review.optionIDs = Array.wrap(params[:optionIDs]) # For some reason, I have to do this manually
    configure_processor!(review, params[:text])
    process_text_and_save review

    # Recompute if the review has been created after the phase has passed (applies to TA reviews for example)
    if review.step.deadline.past? && !review.step.is_a?(Training)
      review.submission.team_submissions.each do |submission|
        submission.grade.compute_grade(recompute: true)
      end
    end

    respond_with review
  end

  def destroy
    review = Review.find(params[:id])
    review.destroy
    unless review.persisted? # deleting failed/rejected
      Xikolo::S3.extract_file_refs(review.text).each do |uri|
        Xikolo::S3.object(uri).delete
      end
    end
    respond_with review
  end

  def decorate(res)
    if res.is_a? Array
      ReviewDecorator.decorate_collection res, context: {raw: params[:raw]}
    else
      res.decorate context: {raw: params[:raw]}
    end
  end

  private

  def index_params
    params.permit :id, :train_review, :submission_id, :user_id, :submitted, :step_id
  end

  def show_params
    params.permit :id, :submission_id, :user_id
  end

  def update_params
    params.permit :optionIDs, :award, :feedback_grade, :submitted
  end

  attr_reader :processor

  def configure_processor!(review, input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :peerassessment,
      purpose: 'peerassessment_review_text',
      current: review.text,
      text: input
    processor.on_new do |upload|
      pid = UUID4(review.step.peer_assessment_id).to_str(format: :base62)
      rid = UUID4(review.id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "assessments/#{pid}/reviews/#{rid}/rtfiles/#{id}/#{upload.sanitized_name}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: "attachment; filename=\"#{upload.sanitized_name}\"",
        content_type: upload.content_type,
      }
    end
  end

  def process_text_and_save(review)
    processor.parse!
    review.text = processor.result
    if processor.valid? && review.save
      processor.obsolete_uris.each do |uri|
        Xikolo::S3.object(uri).delete
      end
    else
      processor.rollback!
      processor.errors.each do |_url, code, _message|
        review.errors.add :text, code.to_s
      end
    end
  end
end
