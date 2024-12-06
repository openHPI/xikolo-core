# frozen_string_literal: true

class PeerAssessment::ReviewPresenter < PrivatePresenter
  def_delegators \
    :@review,
    :award,
    :deadline,
    :extended,
    :feedback_grade,
    :grade,
    :id,
    :optionIDs,
    :step_id,
    :submission_id,
    :submitted,
    :suspended,
    :text,
    :train_review,
    :user_id

  attr_accessor \
    :accusal,
    :filed_conflict,
    :review,
    :review_form

  def self.create(review)
    review_form = PeerAssessment::ReviewForm.new(review)
    new(review:, review_form:).tap do |presenter|
      if presenter.review['id']
        Restify::Promise.new([
          presenter.review.rel(:accusals).get,
          presenter.review.rel(:filed_conflicts).get,
        ]) do |accusals, filed_conflicts|
          presenter.instance_variable_set :@accusal, accusals&.first
          presenter.instance_variable_set :@filed_conflict, filed_conflicts&.first
        end.value
      end
    end
  end

  def filed_conflict!
    @filed_conflict
  end

  def accusal!
    @accusal
  end

  def step
    @review.step_id
  end

  def suspended?
    accused? || conflict_filed?
  end

  def status
    if suspended?
      I18n.t(:'peer_assessment.review.suspended')
    elsif submitted
      I18n.t(:'peer_assessment.review.closed')
    else
      I18n.t(:'peer_assessment.review.open')
    end
  end

  def status_class
    if suspended?
      'danger'
    elsif submitted
      'success'
    else
      'warning'
    end
  end

  def given_grade(assessment)
    if suspended? || grade.nil?
      '—'
    else
      "#{grade} / #{assessment.max_points}"
    end
  end

  def extension_possible?(current_step)
    !extended &&
      (deadline - 3.hours).past? &&
      deadline.future? &&
      !submitted &&
      (deadline < current_step.deadline)
  end

  def time_left
    return '—' if submitted || suspended?

    base    = DateTime.parse(deadline).to_i - DateTime.now.to_i
    hours   = base / 3600
    minutes = (base % 3600) / 60

    "#{hours}h #{minutes}min"
  end

  def to_param
    UUID(id).to_param
  end

  def conflict_filed?
    !filed_conflict!.nil?
  end

  def accused?
    !accusal!.nil?
  end

  def received_review_conflict_filed_title
    I18n.t :'peer_assessment.results.peer_reported_short_submission',
      reason: I18n.t(:"peer_assessment.conflict.reasons.#{filed_conflict!.reason}")
  end

  def received_review_accused_title
    I18n.t :'peer_assessment.results.you_reported_short',
      reason: I18n.t(:"peer_assessment.conflict.reasons.#{accusal!.reason}")
  end

  def written_review_conflict_filed_title
    I18n.t :'peer_assessment.results.you_reported_short',
      reason: I18n.t(:"peer_assessment.conflict.reasons.#{filed_conflict!.reason}")
  end

  def written_review_accused_title
    I18n.t :'peer_assessment.results.peer_reported_short',
      reason: I18n.t(:"peer_assessment.conflict.reasons.#{accusal!.reason}")
  end
end
