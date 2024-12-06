# frozen_string_literal: true

require 'addressable'

class QuizSubmissionPresenter
  # @param submission [Xikolo::Submission::QuizSubmission]
  # @param course [Xikolo::Course::Course]
  # @param item [Xikolo::Course::Item]
  # @param user [Xikolo::Common::Auth::CurrentUser::Base]
  def initialize(submission, course:, item:, user:)
    @submission = submission
    @course = course
    @item = item
    @user = user
  end

  def enable_proctoring_iframes?
    @user.feature?('proctoring') && proctoring_context.enabled?
  end

  def proctoring_cam_iframe
    submission = Quiz::Submission.from_acfs(@submission)
    submission.proctoring.vendor_cam_url
  end

  private

  def proctoring_context
    @proctoring_context ||= Proctoring::ItemContext.new(@course, @item, enrollment)
  end

  def enrollment
    @enrollment ||= Course::Enrollment.active.find_by!(course_id: @course.id, user_id: @user.id)
  end
end
