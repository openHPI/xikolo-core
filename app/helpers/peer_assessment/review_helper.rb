# frozen_string_literal: true

module PeerAssessment::ReviewHelper
  def perform_update_checks(training: false)
    # Perform checks. Error map holds mappings to highlight the errors in the frontend.
    # The convention is as follows:
    # - review text: message -> #review_feedback_form
    # - Rubrics: message -> [error_id_list (rubric_<rubric_id>)]
    errors = {
      messages:  [],
      error_ids: [],
    }

    # Text present? (Only for normal reviews)
    unless training || !params.key?(:xikolo_peer_assessment_review)
      text = params['xikolo_peer_assessment_review']['text']

      if text.empty?
        errors[:messages] << I18n.t('peer_assessment.review.missing_text')
        errors[:error_ids] << 'review_form textarea'
      end
    end

    # All rubrics graded?
    rubrics = params[:rubrics].split
    missing_rubric = false

    rubrics.each do |rubric_id|
      next if params.key? "group_#{rubric_id}"

      errors[:error_ids] << "rubric_#{rubric_id}"
      missing_rubric = true
    end

    errors[:messages] << I18n.t('peer_assessment.review.missing_rubric') if missing_rubric
    errors
  end

  def get_selected_options # rubocop:disable Naming/AccessorMethodName
    rubrics = params[:rubrics].split
    selection = []

    rubrics.each do |rubric_id|
      if params.key? "group_#{rubric_id}"
        selection << params[:"group_#{rubric_id}"]
      end
    end

    selection
  end

  def extend_review_deadline(review)
    if review.extended || (review.deadline - 3.hours).future? || review.deadline.past?
      add_flash_message :error, I18n.t(:'peer_assessment.review.extension_failure')
    else
      review.extended = true

      if review.save
        add_flash_message :success, I18n.t(:'peer_assessment.review.extension_success')
      else
        add_flash_message :error, I18n.t(:'peer_assessment.review.extension_failure')
      end
    end
  end
end
