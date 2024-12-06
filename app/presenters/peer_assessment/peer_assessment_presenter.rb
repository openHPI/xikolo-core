# frozen_string_literal: true

class PeerAssessment::PeerAssessmentPresenter < Presenter
  def_delegators :peer_assessment, :ta_status, :max_points

  attr_accessor :peer_assessment, :submission, :section, :steps, :statistic

  include Rails.application.routes.url_helpers
  include PeerAssessment::ButtonsHelper

  def id
    peer_assessment['id']
  end

  def with_training?
    steps.map(&:type).include? 'Xikolo::PeerAssessment::Training'
  end

  def closed?
    # Only open conflicts can be addressed after the deadline!
    steps.last['deadline'] < Time.zone.today
  end

  # Sort assessments by weeks, then by names
  def <=>(other)
    return unless other.is_a?(self.class)

    [week.to_i, name] <=> [other.week.to_i, other.name]
  end

  def week
    section.try(:position)
  end

  def name
    peer_assessment['title']
  end

  def progress
    '...'
  end

  def grade
    'x/y'
  end

  def status
    '...'
  end

  def awards
    statistic['nominations']
  end

  def conflicts
    statistic['conflicts']
  end

  def pa_button(user, type)
    case type
      when :conflict
        conflicts_button(user)
      when :edit
        edit_button(user)
      when :submission_management
        submission_management_button(user)
      when :trainings_management
        trainings_management_button(user)
      when :show
        show_button(user)
    end
  end

  def to_param
    UUID(id).to_param
  end

  private

  def conflicts_button(user)
    btn_txt = I18n.t(:'peer_assessment.index.admin.conflict_overview')
    btn_href = peer_assessment_conflicts_path(self)
    btn_class = 'btn btn-xs btn-default'
    disabled = disabled(user, 'peerassessment.conflicts.manage', condition: conflicts > 0)
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end

  def edit_button(user)
    btn_txt = I18n.t(:'peer_assessment.index.admin.edit')
    btn_href = edit_peer_assessment_path(self)
    btn_class = 'mr5 btn btn-sm btn-primary'
    disabled = disabled(user, 'peerassessment.peerassessment.view')
    # all admin type users can view the peer_assessment settings
    # editing is disabled by disabling the save buttons
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end

  def show_button(_user)
    btn_txt = I18n.t(:'peer_assessment.index.admin.view')
    btn_href = peer_assessment_path(self)
    btn_class = 'mr5 btn btn-sm btn-default'
    disabled = ''
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end

  def submission_management_button(user)
    btn_txt = I18n.t(:'peer_assessment.index.admin.manage_submissions')
    btn_href = peer_assessment_submission_management_index_path(self)
    btn_class = 'mr5 btn btn-sm btn-default'
    disabled = disabled(user, 'peerassessment.submission.manage')
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end

  def trainings_management_button(user)
    btn_txt = I18n.t(:'peer_assessment.index.admin.view_training')
    btn_href = peer_assessment_train_samples_path(self)
    btn_class = 'btn btn-sm btn-default'
    disabled = disabled(user, 'peerassessment.training_samples.manage', condition: with_training?)
    assemble_button(btn_txt, btn_href, btn_class, disabled)
  end
end
