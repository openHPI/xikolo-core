# frozen_string_literal: true

require 'base64'
require 'logger'
require 'webrick'
require 'yaml'

require 'mail'
require 'midi-smtp-server'

module CapybaraEMail
  def fetch_emails(opts = {})
    recipient = opts.fetch(:to) { context.fetch(:user).fetch('email') }
    subject = opts.fetch(:subject, nil)
    timeout = Integer opts.fetch(:timeout, 45)
    counter = 0

    while counter < timeout
      emails = CapybaraSmtpServer.emails

      emails = emails.select {|e| e.to.include?(recipient) } if recipient
      emails = emails.select {|e| e.subject == subject } unless subject.nil?

      if !emails.nil? && emails.any?
        return emails
      else
        counter += 1
        sleep 1
      end
    end
    if opts.fetch(:allow_no_mails, false) == false
      raise Timeout::Error.new "Did not receive an email for #{recipient} " \
                               "within #{timeout} seconds.\nReceived emails: #{CapybaraSmtpServer.emails.inspect}"
    else
      emails
    end
  end
  # rubocop:enable all

  def open_email(email = nil)
    email ||= fetch_emails.last
    CapybaraMailServlet.email = email

    visit "http://127.0.0.1:11080/#{email.object_id}.html"
    email
  end

  def delete_emails(opts = {})
    recipient = opts.fetch(:to)
    timeout   = Integer opts.fetch(:timeout, 30)

    sleep timeout

    emails = CapybaraSmtpServer.emails
    CapybaraSmtpServer.emails = if recipient
                                  emails.reject! {|e| e.to.include?(recipient) }
                                else
                                  []
                                end
  end
end

class CapybaraMailServlet < WEBrick::HTTPServlet::AbstractServlet
  class << self
    attr_accessor :email

    def server
      @server ||= WEBrick::HTTPServer.new \
        Port: 11_080, Log: false, AccessLog: []
    end
  end

  # rubocop:disable Naming/MethodName
  def do_GET(_, response)
    response.status = 200
    response.content_type = 'text/html'
    response.body = email_content(self.class.email)
  end
  # rubocop:enable Naming/MethodName

  def email_content(email)
    if %r{\Amultipart/(alternative|related|mixed)\Z}.match?(email.mime_type)
      if email.html_part
        return email.html_part.body.to_s
      elsif email.text_part
        return convert_to_html email.text_part.body.to_s
      end
    end

    convert_to_html email.body.to_s
  end

  def convert_to_html(text)
    "<html><body>#{convert_links(text)}</body></html>"
  end

  def convert_links(text)
    text.gsub %r{(https?://\S+)}, %q(<a href="\1">\1</a>)
  end
end

# This is an SMTP server that stores all mails it receives so that they can be
# displayed on a webpage during a test.
class CapybaraSmtpServer < MidiSmtpServer::Smtpd
  class << self
    def emails
      @emails ||= []
    end

    def reset!
      @emails = nil
    end

    def server
      @server ||= new(
        ports: '2525',
        hosts: '127.0.0.1',
        max_processings: 4,
        logger: Logger.new(File.open('log/smtp.log', File::WRONLY | File::APPEND | File::CREAT))
      )
    end

    # Create a new server instance listening at 127.0.0.1:2525
    # and accepting a maximum of 4 simultaneous connections
    def start!
      server.start
    end

    def stop
      server.stop
    end
  end

  def on_message_data_event(context)
    mail = Mail.read_from_string(context[:message][:data])

    self.class.emails << mail
  end
end

Gurke.configure do |c|
  c.include CapybaraEMail

  c.before(:system) do
    CapybaraSmtpServer.start!
    CapybaraMailServlet.server.mount '/', CapybaraMailServlet
    Thread.new { CapybaraMailServlet.server.start }
  end

  c.before(:scenario) do
    CapybaraSmtpServer.reset!
  end

  c.after(:system) do
    CapybaraSmtpServer.stop
    CapybaraMailServlet.server.shutdown
  end
end
