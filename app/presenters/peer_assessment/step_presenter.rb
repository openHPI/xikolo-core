# frozen_string_literal: true

class PeerAssessment::StepPresenter < Presenter
  include PeerAssessment::PeerAssessmentContextHelper
  include Rails.application.routes.url_helpers

  def_delegators :@step, :id, :deadline, :position, :optional, :instance_of?, :peer_assessment_id, :open, :completion,
    :required_reviews, :unlock_date, :training_opened

  attr_accessor :step, :state

  def self.build(step)
    new step:, state: nil
  end

  def current?(step)
    id == step.try(:id)
  end

  def deadline_passed_text
    if @step.is_a? Xikolo::PeerAssessment::SelfAssessment
      I18n.t(:'peer_assessment.step.optional_deadline_passed', deadline: deadline.to_fs(:short))
    else
      I18n.t(:'peer_assessment.step.deadline_passed', deadline: deadline.to_fs(:short))
    end
  end

  def name
    @step.class
  end

  def link(assessment, other_step)
    if available? && !current?(other_step)
      peer_assessment_step_path(short_uuid(assessment.id), short_uuid(id))
    else
      '#'
    end
  end

  def available?
    finished? || open?
  end

  def finished?
    state == :finished
  end

  def open?
    state == :open
  end

  def display_classes(other_step)
    "#{state} #{'current' if current? other_step}"
  end

  def display_icon
    finished? ? 'check' : 'lock'
  end

  def to_param
    UUID(id).to_param
  end

  def unlock_date?
    unlock_date.present?
  end

  def formatted_unlock_date
    "#{I18n.l(unlock_date.in_time_zone.to_datetime,
      format: :very_short_datetime)} #{I18n.t(:'date.timezone')}"
  end

  def deadline?
    deadline.present?
  end

  def formatted_deadline_date
    "#{I18n.l(deadline.try(:in_time_zone).try(:to_datetime),
      format: :very_short_datetime)} #{I18n.t(:'date.timezone')}"
  end

  def open_peer_grading?
    step.is_a?(Xikolo::PeerAssessment::PeerGrading) && open? && !@training_finished && !@training_passed
  end

  def open_result?
    @potential_result_swal && step.is_a?(Xikolo::PeerAssessment::Results) && open? && !@self_assessment_passed
  end

  def locked_class
    'locked' unless available?
  end
end
