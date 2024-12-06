# frozen_string_literal: true

class ReviewDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    fields.as_json(opts)
  end

  private

  def fields
    {
      id:,
      step_id:,
      submission_id:,
      user_id:,
      text:,
      submitted:,
      award:,
      feedback_grade:,
      train_review:,
      optionIDs:, # deprecated
      option_ids: optionIDs,
      deadline:,
      grade: compute_grade,
      extended:,
      conflict: suspended? || accused?,
      suspended: suspended?,
      accused: accused?,
      accusals_url: h.conflicts_url(conflict_subject_id: id),
      filed_conflicts_url: h.conflicts_url(conflict_subject_id: submission_id, reporter: user_id),
    }
  end

  def text
    if context[:raw]
      Xikolo::S3.media_refs(object.text, public: true)
        .merge('markup' => object.text)
    else
      Xikolo::S3.externalize_file_refs(object.text, public: true)
    end
  end
end
