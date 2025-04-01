# frozen_string_literal: true

class AbuseReportPresenter
  def initialize(report)
    @abuse_report = report
    reporter!
  end

  attr_reader :reporter

  def post_type
    I18n.t("pinboard.reporting.admin.post_types.#{@abuse_report['reportable_type'].underscore}")
  end

  def question_title
    @abuse_report['question_title']
  end

  def user_id
    @abuse_report['user_id']
  end

  def created_at
    @abuse_report['created_at']
  end

  def url
    @abuse_report['url']
  end

  private

  def reporter!
    @reporter = Rails.cache.fetch("users/#{user_id}/name") do
      Xikolo.api(:account).value!.rel(:user).get({id: user_id}).value!['name']
    end
  end
end
