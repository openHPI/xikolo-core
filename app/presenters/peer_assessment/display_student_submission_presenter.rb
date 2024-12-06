# frozen_string_literal: true

class PeerAssessment::DisplayStudentSubmissionPresenter < Presenter
  attr_accessor :peer_assessment, :submission_id

  def_delegators :peer_assessment

  include Rails.application.routes.url_helpers
  include PeerAssessment::ButtonsHelper
  include ActionView::Context

  def action_button(path, type)
    btn_class = 'btn btn-primary btn-xs'
    disabled = disabled(!path.nil?)
    p_class = p_class(!path.nil?)
    path =  '#' if path.nil?
    case type
      when :submission
        btn_txt = I18n.t(:'peer_assessment.submission_management.display_student_submission.submission_page')
        tag.p(class: p_class, style: 'display: inline-block;') do
          assemble_button(btn_txt, path, btn_class, disabled)
        end
      when :training
        btn_txt = I18n.t(:'peer_assessment.submission_management.display_student_submission.training_page')
        tag.p(class: p_class, style: 'display: inline-block;') do
          assemble_button(btn_txt, path, btn_class, disabled)
        end
      when :peer_evaluation
        btn_txt = I18n.t(:'peer_assessment.submission_management.display_student_submission.peer_grading_page')
        tag.p(style: 'display: inline-block;') do
          assemble_button(btn_txt, path, btn_class, disabled, '_blank')
        end
      when :self_evaluation
        btn_txt = I18n.t(:'peer_assessment.submission_management.display_student_submission.self_assessment_page')
        tag.p(class: p_class, style: 'display: inline-block;') do
          assemble_button(btn_txt, path, btn_class, disabled)
        end
      when :results
        btn_txt = I18n.t(:'peer_assessment.submission_management.display_student_submission.results_page')
        tag.p do
          assemble_button(btn_txt, path, btn_class, disabled, '_blank')
        end
    end
  end

  def draft_hint(condition)
    if condition
      tag.p(style: 'display: inline;') do
        I18n.t(:'peer_assessment.submission_management.display_student_submission.draft_hint')
      end
    end
  end

  private

  def p_class(condition)
    condition ? 'students_peerassessment' : ''
  end

  def disabled(condition)
    condition ? '' : 'disabled'
  end
end
