# frozen_string_literal: true

# TODO: Do not use instance variables
# rubocop:disable Rails/HelperInstanceVariable

module PeerAssessment::RubricHelper
  # Peer assessment rubric helper

  def load_rubrics
    rubrics ||= Xikolo.api(:peerassessment).value!.rel(:rubrics).get(peer_assessment_id: @assessment.id).value!
    @rubric_presenters = build_rubric_presenters rubrics
  end

  def build_rubric_presenters(rubrics)
    rubrics.map {|rubric| PeerAssessment::RubricPresenter.create(rubric) }
  end
end

# rubocop:enable all
