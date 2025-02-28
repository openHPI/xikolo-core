# frozen_string_literal: true

module PeerAssessment::ButtonsHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Context
  # TODO: PA introduce new roles and rights

  def disabled(user, permission, condition: true)
    condition && user.allowed?(permission) ? '' : 'disabled'
  end

  def assemble_button( # rubocop:disable Metrics/ParameterLists
    btn_txt,
    btn_href,
    btn_class,
    disabled,
    target = '_self',
    options = {},
    &
  )
    btn_class = "#{btn_class} #{disabled}"
    options.merge!(class: btn_class, target:, disabled: (disabled == 'disabled') || nil)
    if btn_txt
      link_to(btn_txt, btn_href, options, &)
    else
      link_to(btn_href, options, &)
    end
  end

  def assemble_submit(btn_txt, btn_class, disabled, options = {})
    btn_class = "#{btn_class} #{disabled}"
    options[:class] = btn_class
    options[:disabled] = (disabled == 'disabled') || nil
    submit_tag btn_txt, options
  end

  def assemble_icon_button(btn_class, disabled, options = {}, &)
    btn_class = "#{btn_class} #{disabled}"
    options[:class] = btn_class
    options[:disabled] = (disabled == 'disabled') || nil
    button_tag(options, &)
  end

  def create_new_or_resume_button( # rubocop:disable Metrics/ParameterLists
    first_entering,
    next_sample,
    additional_sample,
    assessment_id,
    current_step_id,
    teacherview
  )
    path = new_peer_assessment_step_training_url(short_uuid(assessment_id), short_uuid(current_step_id))
    if first_entering
      label = t(:'peer_assessment.training.first_sample')
    elsif next_sample
      label = t(:'peer_assessment.training.next_sample')
    elsif additional_sample
      label = t(:'peer_assessment.training.additional_sample')
    end
    if first_entering || next_sample || additional_sample
      link_to label, path, class: "btn btn-primary mr10 #{'disabled' if teacherview}"
    end
  end

  def create_advance_form(passed, form)
    if passed
      btn_class = ''
    else
      btn_class = 'js-submit-confirm'
    end

    form_tag form[:advance_path],
      class: btn_class,
      style: 'display: inline-block',
      method: 'put',
      data: {
        confirm_title: form[:confirm_title],
        confirm_message: form[:confirm_message],
        confirm_button: form[:confirm_button],
        cancel_button: form[:cancel_button],
      }
  end
end
