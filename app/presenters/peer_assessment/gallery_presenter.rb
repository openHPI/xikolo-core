# frozen_string_literal: true

class PeerAssessment::GalleryPresenter < Presenter
  # TODO: PA introduce new roles and rights
  def_delegators :peer_assessment, :id
  attr_accessor  :peer_assessment

  include ActionView::Helpers::TagHelper
  include Rails.application.routes.url_helpers
  include PeerAssessment::ButtonsHelper

  def to_param
    UUID(peer_assessment.id).to_param
  end

  def create_template_button(user)
    btn_txt = I18n.t(:'peer_assessment.submission_management.generate_gallery')
    btn_href = generate_gallery_peer_assessment_submission_management_index_path(self)
    btn_class = 'col-md-12 btn btn-primary btn-sm#generate-gallery-button'
    gallery_enabled = !peer_assessment.gallery_entries.empty?
    disabled = disabled(user, 'peerassessment.gallery.create', condition: gallery_enabled)
    target = '_blank'
    assemble_button(btn_txt, btn_href, btn_class, disabled, target)
  end

  def template_button_info(user)
    gallery_enabled = !peer_assessment.gallery_entries.empty?
    if !user.allowed? 'peerassessment.gallery.create'
      tag.span('',
        class: %w[em1-5 mt5 xi-icon fa-regular fa-comment-question cpointer],
        aria_label: I18n.t('peer_assessment.administration.missing_permission'),
        data: {tooltip: I18n.t('peer_assessment.administration.missing_permission')})
    elsif !gallery_enabled
      tag.span('',
        class: %w[em1-5 mt5 xi-icon fa-regular fa-comment-question cpointer],
        aria_label: I18n.t('peer_assessment.submission_management.gallery_button_disabled_info'),
        data: {tooltip: I18n.t('peer_assessment.submission_management.gallery_button_disabled_info')})
    end
  end
end
