# frozen_string_literal: true

class PeerAssessment::SubmissionPresenter < PrivatePresenter
  attr_accessor :submission

  include PeerAssessment::ButtonsHelper
  include Rails.application.routes.url_helpers

  # rubocop:disable Style/OptionalBooleanParameter
  # The `get_user` parameter is used in `PeerAssessment::SubmissionManagementController`
  # which itself needs a larger refactoring regarding rubocop.
  def self.create(submission, get_user = false)
    new(submission:).tap do |presenter|
      presenter.grade! if get_user
    end
  end
  # rubocop:enable all

  def grade!
    @grade ||= Xikolo.api(:peerassessment).value!.rel(:grade).get(id: grade).value
  end

  def user!
    @user ||= Xikolo.api(:account).value!.rel(:user).get(id: user_id).value!
  end

  def id
    @submission['id']
  end

  def shared_submission_id
    @submission['shared_submission_id']
  end

  def user_id
    @submission['user_id']
  end

  def nominations
    @submission['nominations']
  end

  def votes
    @submission['votes']
  end

  def average_votes
    @submission['average_votes']
  end

  def grade
    @submission['grade']
  end

  def text
    @submission['text']
  end

  def user
    @submission['user']
  end

  def attachments
    @submission['attachments']
  end

  def submitted
    @submission['submitted']
  end

  def additional_attempts
    @submission['additional_attempts']
  end

  def gallery_opt_out
    @submission['gallery_opt_out']
  end

  def team_name
    @submission['team_name']
  end

  def created_at
    @submission['created_at'].to_datetime.to_formatted_s(:short)
  end

  def updated_at
    @submission['updated_at'].to_datetime.to_formatted_s(:short)
  end

  def base_points_from_grade
    if grade!.nil? || grade!['base_points'].blank?
      '-'
    else
      grade!['base_points']
    end
  end

  def view_submission_button(user, peer_assessment_id)
    btn_txt = I18n.t(:'peer_assessment.submission_management.view')
    btn_href = peer_assessment_submission_management_path(id:, peer_assessment_id:)
    btn_class = 'btn btn-xs btn-default'
    disabled = disabled(user, 'peerassessment.submission.inspect')
    assemble_button(btn_txt, btn_href, btn_class, disabled, '_blank')
  end
end
