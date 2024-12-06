# frozen_string_literal: true

class PeerAssessment::ReviewFormPresenter < PrivatePresenter
  include Rails.application.routes.url_helpers

  # Encapsulates parameters used to build the peer review form as needed for
  # each step requiring some kind of review form. Thus, the controllers can
  # easily configure what form they need.

  attr_accessor \
    :as_collapsible,
    :assessment,
    :confirm_message,
    :confirm_title,
    :conflict_id,
    :enable_autosave,
    :enable_awards,
    :enable_qualitative_feedback,
    :enable_reporting,
    :enable_summative_feedback,
    :is_optional,
    :purpose,
    :review,
    :show_bottom_info,
    :small_buttons,
    :small_headlines,
    :submit_button_text,
    :text_required

  def self.create(assessment, review, purpose)
    new(
      as_collapsible: false,
      assessment:,
      confirm_message: I18n.t(:'peer_assessment.review.submit_message'),
      confirm_title: I18n.t(:'peer_assessment.review.submit_message_title'),
      enable_autosave: true,
      enable_awards: false,
      enable_qualitative_feedback: true,
      enable_reporting: false,
      enable_summative_feedback: true,
      is_optional: false,
      purpose:, # E.g. training samples, review, student training
      review:,
      show_bottom_info: false,
      small_buttons: false,
      small_headlines: false,
      submit_button_text: I18n.t(:'global.submit'),
      text_required: true
    )
  end

  def headline(text)
    if small_headlines
      "<h5>#{text}</h5>"
    else
      "<h4>#{text}</h4>"
    end
  end

  def short_uuid(id)
    UUID(id).to_param
  end

  def autosave_url
    if enable_autosave
      case purpose
        when 'training_sample'
          autosave_peer_assessment_train_sample_path(assessment.id, review.id)
        when 'student_training'
          autosave_peer_assessment_step_training_path(
            short_uuid(assessment.id),
            short_uuid(review.step),
            id: short_uuid(review.id)
          )
        when 'regular_review', 'ta_review'
          autosave_peer_assessment_step_review_path(
            short_uuid(assessment.id),
            short_uuid(review.step),
            id: short_uuid(review.id)
          )
        when 'self_assessment'
          autosave_peer_assessment_step_self_assessments_path(
            short_uuid(assessment.id),
            short_uuid(review.step),
            id: short_uuid(review.id)
          )
      end
    end
  end

  def submit_url
    case purpose
      when 'training_sample'
        peer_assessment_train_sample_path short_uuid(assessment.id), id: short_uuid(review.id)
      when 'student_training'
        peer_assessment_step_training_path short_uuid(assessment.id), short_uuid(review.step), id: short_uuid(review.id)
      when 'regular_review'
        peer_assessment_step_review_path short_uuid(assessment.id), short_uuid(review.step), id: short_uuid(review.id)
      when 'self_assessment'
        peer_assessment_step_self_assessments_path(
          short_uuid(assessment.id), short_uuid(review.step), id: short_uuid(review.id)
        )
      when 'ta_review' # TA review during conflict resolution
        reconcile_peer_assessment_conflict_path short_uuid(assessment.id), short_uuid(conflict_id)
    end
  end
end
