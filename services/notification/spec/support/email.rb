# frozen_string_literal: true

require 'mail'
def fetch_mail(opts = {})
  fetch_mails(opts).last
end

def fetch_mails(opts = {})
  timeout = opts.fetch(:timeout, 4)
  size    = opts.fetch(:size, 1)

  Timeout.timeout(timeout) do
    sleep 0.1 while (mails = self.mails).size <= size
    mails
  end
rescue Timeout::Error
  raise Timeout::Error.new \
    "Did not receive at least #{size} email within #{timeout}s."
end

def mails
  ActionMailer::Base.deliveries
end

def mail
  mails.last
end

module MailPatch
  def content
    conv_str _best_part
  end

  def _best_part
    html_part || text_part || self
  end

  def text
    conv_str text_part
  end

  def html
    conv_str html_part
  end

  def conv_str(part)
    part.try(:body).try(:raw_source).try(:to_s)
  end
end

Mail::Message.include MailPatch
