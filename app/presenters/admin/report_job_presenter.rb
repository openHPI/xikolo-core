# frozen_string_literal: true

class Admin::ReportJobPresenter
  def initialize(job, user)
    @job = job
    @user = user
  end

  def id
    @job['id']
  end

  def task_type
    @job['task_type']
  end

  def annotation
    @job['annotation']
  end

  def status
    @job['status']
  end

  def download_url
    @job['download_url']
  end

  def progress
    @job['progress']
  end

  def expires_at
    I18n.t(
      :'reports.jobs.expire_date',
      date: I18n.l(
        Time.zone.parse(@job['file_expire_date']), format: :long_datetime
      )
    )
  end

  def expiry_date?
    @job['file_expire_date'].present?
  end

  def progress?
    status == 'started'
  end

  def downloadable?
    return false if @user.masqueraded?

    status == 'done' && download_url.present?
  end

  def error?
    status == 'failing'
  end

  def deletable?
    %w[done failing].include? status
  end

  def restartable?
    status == 'failing'
  end

  def error_html
    error = @job['error_text']

    return "<p>#{I18n.t(:'reports.jobs.no_error_details')}</p>" unless error

    "<pre>#{error}</pre>"
  end
end
