# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  prepend_view_path "brand/#{Xikolo.brand}/views"
  layout 'old'

  helper :mailer

  private

  # Hook mail call to add inline attachment of brand specific
  # logo if it exist
  def mail(*args)
    args[0][:from] = Xikolo.config.mailsender

    super
  end
end
