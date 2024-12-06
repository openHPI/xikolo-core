# frozen_string_literal: true

class PeerAssessment::SubmissionManagementPresenter < Presenter
  # TODO: PA introduce new roles and rights
  attr_accessor :peer_assessment, :submission_id

  def_delegators :peer_assessment

  include PeerAssessment::ButtonsHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::FormTagHelper

  def provide_new_attempt_button(user)
    btn_txt = I18n.t(:'peer_assessment.submission_management.additional_attempts.button')
    btn_class = 'btn btn-sm btn-primary'
    enabled = user.allowed? 'peerassessment.submission.grant_attempt'
    button_tag(btn_txt, type: 'submit', class: btn_class, disabled: !enabled)
  end

  def trigger_regrading_button(user)
    btn_txt = I18n.t(:'peer_assessment.submission_management.regrading_request.button')
    btn_class = 'btn btn-sm btn-primary'
    btn_id = 'request-regrading-button'
    enabled = user.allowed? 'peerassessment.submission.request_regrading'
    button_tag(btn_txt, type: 'button', class: btn_class, id: btn_id, disabled: !enabled)
  end
end
