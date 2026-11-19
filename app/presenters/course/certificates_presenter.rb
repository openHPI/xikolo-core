# frozen_string_literal: true

class Course::CertificatesPresenter
  def initialize(course_id:, user_id:, current_user:)
    @achievements = CourseService::Achievements.new(course_id, user_id)
    @user_id = user_id
    @current_user = current_user
  end

  def any?
    cards.any?
  end

  def cards
    @cards ||= [
      (card(Certificate::Record::COP) if @achievements.cop.enabled?),
      (card(Certificate::Record::ROA) if @achievements.roa.enabled?),
    ].compact
  end

  def unlock_status
    return :none_unlocked unless cards.any?(&:achieved?)

    cards.all?(&:achieved?) ? :all_unlocked : :partially_unlocked
  end

  def mascot_message
    status = unlock_status
    return unless status == :all_unlocked || @achievements.cop.achievable? || @achievements.roa.achievable?

    I18n.t(status, scope: 'course.progress.certificates.mascot')
  end

  private

  def card(type)
    Course::CertificateCardPresenter.new(
      type,
      @achievements,
      user_id: @user_id,
      # The render endpoint always issues the PDF for the current user.
      # Teachers can open a learner's progress via the `user_id` param, but
      # would get their own record (or a 404) instead of the learner's, so
      # the download is hidden for them.
      downloadable_by_viewer: @user_id == @current_user.id
    )
  end
end
