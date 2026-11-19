# frozen_string_literal: true

class Course::CertificateCardPresenter
  include Rails.application.routes.url_helpers

  EMPTY_STATE = '—'

  I18N_SCOPES = {
    Certificate::Record::COP => 'course_service.achievements.certificates.confirmation',
    Certificate::Record::ROA => 'course_service.achievements.certificates.achievement',
  }.freeze

  def initialize(type, achievements, user_id:, downloadable_by_viewer:)
    @type = type
    @achievements = achievements
    @user_id = user_id
    @downloadable_by_viewer = downloadable_by_viewer
  end

  attr_reader :type

  def title
    I18n.t(:name, scope: i18n_scope)
  end

  def description
    return I18n.t(state, scope: [i18n_scope, :state]) if cop?

    roa_description
  end

  def requirement
    if cop?
      I18n.t(:'requirements.progress', scope: i18n_scope, course_percentage: course.cop_threshold_percentage.to_i)
    elsif course.exam?
      I18n.t(:'requirements.completion_with_exam', scope: i18n_scope, pass_percentage: course.exam_pass_percentage)
    else
      I18n.t(:'requirements.completion', scope: i18n_scope, course_percentage: course.roa_threshold_percentage.to_i)
    end
  end

  def achieved?
    if cop?
      @achievements.cop.achieved? || @achievements.cop.achieved_via_roa?
    else
      @achievements.roa.achieved?
    end
  end

  def issued_on
    return I18n.t(:'course.progress.certificates.not_available_yet') unless course.records_released?
    return EMPTY_STATE unless achieved?
    return I18n.t(:'course.progress.certificates.not_downloaded_yet') if record.nil?

    I18n.l(record.created_at.to_date)
  end

  def download_path
    return unless downloadable?

    certificate_render_path(course_id: course.id, type:)
  end

  private

  def downloadable?
    @downloadable_by_viewer && course.records_released? && achieved? && template?
  end

  def cop?
    type == Certificate::Record::COP
  end

  # Courses with an exam use exam-specific texts where a dedicated variant
  # exists, falling back to the generic state text otherwise.
  def roa_description
    exam_state = :"#{state}_with_exam"
    if course.exam? && I18n.exists?(exam_state, scope: [i18n_scope, :state])
      I18n.t(exam_state, scope: [i18n_scope, :state])
    else
      I18n.t(state, scope: [i18n_scope, :state])
    end
  end

  def state
    cop? ? @achievements.cop_state : @achievements.roa_state
  end

  def i18n_scope
    I18N_SCOPES.fetch(type)
  end

  def course
    @achievements.course
  end

  def record
    return @record if defined?(@record)

    @record = Certificate::Record.find_by(course_id: course.id, user_id: @user_id, type:)
  end

  def template?
    Certificate::Template.exists?(course_id: course.id, certificate_type: type)
  end
end
