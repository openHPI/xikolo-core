# frozen_string_literal: true

class PeerAssessment::PeerAssessmentEditPresenter < Presenter
  def_delegators :peer_assessment, :id

  attr_accessor  :peer_assessment

  include Rails.application.routes.url_helpers
  include PeerAssessment::ButtonsHelper
  include ActionView::Helpers::TagHelper
  include UUIDHelper

  def pa_button(user, type, options = {})
    case type
      when :save_configuration
        save_configuration_button(user)
      when :add_attachment
        edit_button(user)
      when :delete_attachment
        submission_management_button(user)
      when :create_workflow_steps
        create_workflow_button(user)
      when :update_workflow_steps
        update_workflow_button(user)
      when :add_rubric
        add_rubric_button(user)
      when :edit_rubric
        edit_rubric_button(user, options[:presenter_id])
      when :delete_rubric
        delete_rubric_button(user)
      when :move_rubric_up
        move_rubric_up_button(user)
      when :move_rubric_down
        move_rubric_down_button(user)
    end
  end

  private

  def disabled?(user)
    disabled(user, 'peerassessment.peerassessment.edit')
  end

  def save_configuration_button(user)
    btn_txt = I18n.t(:'peer_assessment.administration.save_changes')
    btn_class = 'btn btn-primary mt30 col-md-offset-3 col-lg-offset-3'
    assemble_submit(btn_txt, btn_class, disabled?(user))
  end

  def conflicts_button(user)
    btn_txt = I18n.t(:'peer_assessment.index.admin.conflict_overview')
    btn_href = peer_assessment_conflicts_path(self)
    btn_class = 'btn btn-xs btn-default'
    disabled = disabled(user, 'peerassessment.conflicts.manage', condition: conflicts > 0)
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end

  def create_workflow_button(user)
    btn_txt = I18n.t :'peer_assessment.administration.steps.select_steps'
    btn_class = 'mt20 btn btn-primary btn-sm'
    assemble_submit(btn_txt, btn_class, disabled?(user), form: 'select-steps-form')
  end

  def update_workflow_button(user)
    btn_txt = I18n.t :'peer_assessment.administration.steps.update'
    btn_class = 'col-md-offset-3 col-lg-offset-3 mt30 btn btn-primary btn-sm'
    assemble_submit(btn_txt, btn_class, disabled?(user))
  end

  def edit_rubric_button(user, presenter_id)
    btn_title = I18n.t(:'peer_assessment.administration.rubrics.edit')
    btn_class = 'btn btn-link btn-xs'
    btn_href = edit_peer_assessment_rubric_path(short_uuid(id), presenter_id)
    assemble_button(nil, btn_href, btn_class, disabled?(user), '_self', aria_label: btn_title,
      data: {tooltip: btn_title}) do
      tag.i('', class: 'xi-icon fa-solid fa-pen-to-square black')
    end
  end

  def add_rubric_button(user)
    btn_txt = I18n.t(:'peer_assessment.administration.rubrics.new')
    btn_href = new_peer_assessment_rubric_path(short_uuid(id))
    btn_class = 'btn btn-primary btn-sm col-md-2 col-lg-2 col-xs-12'
    disabled = disabled?(user)
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end

  def delete_rubric_button(user)
    btn_title = I18n.t(:'peer_assessment.administration.rubrics.delete')
    btn_class = 'btn btn-xs btn-link'
    assemble_icon_button btn_class, disabled?(user), aria_label: btn_title, data: {tooltip: btn_title} do
      tag.i('', class: 'xi-icon fa-solid fa-trash-can red')
    end
  end

  def move_rubric_up_button(user)
    btn_title = I18n.t(:'peer_assessment.administration.rubrics.moveup')
    btn_class = 'btn btn-xs btn-link'
    assemble_icon_button(btn_class, disabled?(user), aria_label: btn_title, data: {tooltip: btn_title}) do
      tag.i('', class: 'xi-icon fa-solid fa-chevron-up black')
    end
  end

  def move_rubric_down_button(user)
    btn_title = I18n.t(:'peer_assessment.administration.rubrics.movedown')
    btn_class = 'btn btn-xs btn-link'
    assemble_icon_button(btn_class, disabled?(user), aria_label: btn_title, data: {tooltip: btn_title}) do
      tag.i('', class: 'xi-icon fa-solid fa-chevron-down black')
    end
  end
end
