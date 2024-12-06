# frozen_string_literal: true

class PeerAssessmentConsumer < Msgr::Consumer
  include Notify

  ### Conflict ###

  def new_conflict
    begin
      @conflict = pa_service.rel(:conflict).get(id: conflict_id).value!
    rescue Restify::NotFound
      # Return and implicitly acknowledge message when the conflict is not found.
      return
    end

    @assessment = pa_service.rel(:peer_assessment).get(id: @conflict['peer_assessment_id']).value!

    course = course_service.rel(:course).get(id: @assessment['course_id']).value!

    message.try :ack

    I18n.with_locale(course['lang']) do
      unless @conflict['reason'] == 'no_reviews'
        if @conflict['reason'] == 'grading_conflict'
          notify_regrading_new_conflict
        else
          notify_accused_student_new_conflict
          notify_reporter_new_conflict
        end
      end
    end
  end

  def conflict_resolved
    @conflict = pa_service.rel(:conflict).get(id: conflict_id).value!
    @assessment = pa_service.rel(:peer_assessment).get(id: @conflict['peer_assessment_id']).value!

    course = course_service.rel(:course).get(id: @assessment['course_id']).value!

    message.try :ack

    I18n.with_locale(course['lang']) do
      if @conflict['reason'] == 'grading_conflict'
        notify_regrading_resolved_conflict
      else
        notify_reporter_resolved_conflict
        notify_accused_student_resolved_conflict
      end
    end
  end

  private

  def notify_reporter_new_conflict
    return unless @conflict['reporter']

    reason = I18n.t(:"notifications.peer_assessments.conflict.reasons.#{@conflict['reason']}")

    params = {
      subject: I18n.t(:'notifications.peer_assessments.conflict.new.reporter.subject',
        assessment_name: @assessment['title']),
      title: I18n.t(:'notifications.peer_assessments.conflict.new.reporter.title',
        assessment_name: @assessment['title'],
        reason:),
      body: I18n.t(:'notifications.peer_assessments.conflict.new.reporter.body'),
      referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
        refid: short_uuid(@conflict['id'])),
      reason:,
    }

    notify @conflict['reporter'], 'peer_assessments.conflict.new.reporter', params
  end

  def notify_accused_student_new_conflict
    return unless @conflict['accused']

    conflict_subject = I18n.t(
      :"notifications.peer_assessments.conflict.subjects.#{@conflict['conflict_subject_type'].downcase}"
    )
    reason = I18n.t(:"notifications.peer_assessments.conflict.reasons.#{@conflict['reason']}")

    params = {
      subject: I18n.t(:'notifications.peer_assessments.conflict.new.accused_student.subject',
        conflict_subject:, assessment_name: @assessment['title'], reason:),

      title: I18n.t(:'notifications.peer_assessments.conflict.new.accused_student.title',
        conflict_subject:, reason:, assessment_name: @assessment['title']),

      body: I18n.t(:'notifications.peer_assessments.conflict.new.accused_student.body',
        conflict_subject:, reason:),

      referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
        refid: short_uuid(@conflict['id'])),
      conflict_subject:,
      reason:,
    }

    notify @conflict['accused'], 'peer_assessments.conflict.new.accused_student', params
  end

  def notify_regrading_new_conflict
    return unless @conflict['reporter']

    reason = I18n.t(:"notifications.peer_assessments.conflict.reasons.#{@conflict['reason']}")

    params = {
      subject: I18n.t(:'notifications.peer_assessments.conflict.new.regrading.subject',
        assessment_name: @assessment['title']),
      title: I18n.t(:'notifications.peer_assessments.conflict.new.regrading.title',
        assessment_name: @assessment['title'],
        reason:),
      body: I18n.t(:'notifications.peer_assessments.conflict.new.regrading.body'),
      referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
        refid: short_uuid(@conflict['id'])),
      reason:,
    }

    notify @conflict['reporter'], 'peer_assessments.conflict.new.reporter', params
  end

  def notify_reporter_resolved_conflict
    return unless @conflict['reporter']

    if @conflict['reason'] == 'no_reviews'
      params = {
        subject: I18n.t(:'notifications.peer_assessments.conflict.resolved.no_reviews.subject',
          assessment_name: @assessment['title']),
        title: I18n.t(:'notifications.peer_assessments.conflict.resolved.no_reviews.title',
          assessment_name: @assessment['title']),
        body: I18n.t(:'notifications.peer_assessments.conflict.resolved.no_reviews.body'),
        referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
          refid: short_uuid(@conflict['id'])),
      }
    else
      reason = I18n.t(:"notifications.peer_assessments.conflict.reasons.#{@conflict['reason']}")

      params = {
        subject: I18n.t(:'notifications.peer_assessments.conflict.resolved.reporter.subject',
          assessment_name: @assessment['title']),
        title: I18n.t(:'notifications.peer_assessments.conflict.resolved.reporter.title',
          assessment_name: @assessment['title']),
        body: I18n.t(:'notifications.peer_assessments.conflict.resolved.reporter.body',
          reason:),
        referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
          refid: short_uuid(@conflict['id'])),
        reason:,
      }
    end

    notify @conflict['reporter'], 'peer_assessments.conflict.resolved.reporter', params
  end

  def notify_accused_student_resolved_conflict
    return unless @conflict['accused']

    conflict_subject = I18n.t(
      :"notifications.peer_assessments.conflict.subjects.#{@conflict['conflict_subject_type'].downcase}"
    )
    reason = I18n.t(:"notifications.peer_assessments.conflict.reasons.#{@conflict['reason']}")

    params = {
      subject: I18n.t(:'notifications.peer_assessments.conflict.resolved.accused_student.subject',
        assessment_name: @assessment['title']),
      title: I18n.t(:'notifications.peer_assessments.conflict.resolved.accused_student.title',
        assessment_name: @assessment['title']),
      body: I18n.t(:'notifications.peer_assessments.conflict.resolved.accused_student.body',
        reason:,
        conflict_subject:),
      referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
        refid: short_uuid(@conflict['id'])),
      conflict_subject:,
      reason:,
    }

    notify @conflict['accused'], 'peer_assessments.conflict.resolved.accused_student', params
  end

  def notify_regrading_resolved_conflict
    return unless @conflict['reporter']

    reason = I18n.t(:"notifications.peer_assessments.conflict.reasons.#{@conflict['reason']}")

    params = {
      subject: I18n.t(:'notifications.peer_assessments.conflict.resolved.regrading.subject',
        assessment_name: @assessment['title']),
      title: I18n.t(:'notifications.peer_assessments.conflict.resolved.regrading.title',
        assessment_name: @assessment['title']),
      body: I18n.t(:'notifications.peer_assessments.conflict.resolved.regrading.body',
        reason:),
      referral: I18n.t(:'notifications.peer_assessments.conflict.referral',
        refid: short_uuid(@conflict['id'])),
      reason:,
    }

    notify @conflict['reporter'], 'peer_assessments.conflict.resolved.reporter', params
  end

  def conflict_id
    payload.fetch(:id)
  end

  def course_service
    @course_service ||= Xikolo.api(:course).value!
  end

  def pa_service
    @pa_service ||= Xikolo.api(:peerassessment).value!
  end

  def short_uuid(uid)
    UUID4(uid).to_str(format: :base62)
  end
end
