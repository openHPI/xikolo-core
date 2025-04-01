# frozen_string_literal: true

require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec/matchers'
require 'selenium-webdriver'

require_relative 'capybara_downloads'

def headless?
  if ENV.key?('HEADLESS')
    %w[0 off false no].exclude?(ENV['HEADLESS'])
  elsif ENV.key?('CI')
    %w[0 off false no].exclude?(ENV['CI'])
  else
    true
  end
end

def snap?
  if ENV.key?('SNAP')
    %w[0 off false no].exclude?(ENV['SNAP'])
  else
    false
  end
end

module SlowMode
  SLOW_MODE = ENV['SLOW'].to_i

  def execute(*)
    sleep(0.05 * SLOW_MODE)
    super
  end

  if SLOW_MODE > 0
    warn 'Capybara: SLOW MODE enabled'
    Selenium::WebDriver::Remote::Bridge.prepend self
  end
end

Capybara.app_host = BASE_URI.to_s
Capybara.default_max_wait_time = ENV.fetch('TIMEOUT', 10).to_i

Capybara.register_driver :firefox do |app|
  binary = snap? ? '/snap/firefox/current/usr/lib/firefox/firefox' : nil
  options = Selenium::WebDriver::Firefox::Options.new(binary:).tap do |opts|
    if headless?
      opts.add_argument('-headless')
    end

    opts.add_preference('browser.download.dir', CapybaraDownloads.download_directory.to_s)
    opts.add_preference('browser.download.folderList', 2)
    opts.add_preference('browser.download.manager.showWhenStarting', false)
    opts.add_preference('browser.download.useDownloadDir', true)
    opts.add_preference('browser.helperApps.alwaysAsk.force', false)
    opts.add_preference('browser.helperApps.neverAsk.saveToDisk', 'application/pdf')
    opts.add_preference('intl.accept_languages', 'en')
    opts.add_preference('pdfjs.disabled', true)
  end

  Capybara::Selenium::Driver.new(app, browser: :firefox, options:)
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  # Use BiDi mode since that reports a few more errors in much better
  # ways, such as aborted concurrent navigation issues.
  options.web_socket_url = true

  # TODO: Chrome 129 and later does not wait on all navigational events
  # which break some assertion and assumptions and breaks navigation
  # without assertions between:
  #
  #   * https://github.com/teamcapybara/capybara/issues/2800
  #
  options.browser_version = '128'

  # Chrome for Testing (CfT) cannot run a user-based sandbox on modern
  # systems, locally as well as headless CI servers.
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')

  if headless?
    options.add_argument('--headless=new')
  end

  options.add_argument('--disable-search-engine-choice-screen')
  options.add_argument('--disable-site-isolation-trials')
  options.add_argument('--window-size=1280,1024')

  options.add_preference('download.default_directory', CapybaraDownloads.download_directory.to_s)
  options.add_preference('download.prompt_for_download', false)
  options.add_preference('intl.accept_languages', 'en')
  options.add_preference('plugins.plugins_disabled', ['Chrome PDF Viewer'])

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

case ENV.fetch('BROWSER', 'chrome')
  when /^(firefox|iceweasel|gecko)$/i
    Capybara.default_driver = :firefox
  when /^chrom(e|ium)$/i
    Capybara.default_driver = :chrome
end

Gurke.configure do |c|
  c.include Capybara::DSL, type: :feature
  c.include Capybara::RSpecMatchers, type: :feature

  c.before(:system) do
    Capybara.page.driver.browser.manage.window.resize_to 1280, 1024
    Capybara.page.driver.browser.manage.delete_all_cookies
    Capybara.visit '/'

    $stdout.puts '(~) Browser started.'
  end

  c.before(:scenario) do
    # As per the W3C WebDriver specification, `delete_all_cookies` (called by
    # `reset_sessions!` below) removes only the cookies for the current page's
    # browsing context. Thus, when a test case ends up on a different host
    # (e.g. when viewing sent emails in the browser), we first need to navigate
    # to the homepage in order to clear all Xikolo-related cookies.
    #
    # See https://www.w3.org/TR/webdriver/#delete-all-cookies.

    # To determine whether we are still on our main host, we need to check the
    # current host. However, the `page.current_host` method only returns the
    # scheme and host, but not the port. Thus, we need to manually construct the
    # host part and compare it to the given BASE_URI.
    uri = URI.parse(page.current_url)
    port = uri.port == uri.default_port ? '' : ":#{uri.port}"
    current_host = uri.host ? "#{uri.scheme}://#{uri.host}#{port}" : nil

    visit '/' if current_host != BASE_URI.to_s

    Capybara.reset_sessions!

    # Workaround for "Node with given id does not belong to the
    # document". See
    # https://github.com/teamcapybara/capybara/issues/2800#issuecomment-2728801284.
    #
    # Try handling these unknown errors (can't filter on the message
    # too) as if the element were stale, which means that capybara will
    # look up the selector again, e.g. on the new page that is now
    # loaded.
    if page.driver.respond_to?(:invalid_element_errors) &&
       page.driver.invalid_element_errors.exclude?(Selenium::WebDriver::Error::UnknownError)
      page.driver.invalid_element_errors << Selenium::WebDriver::Error::UnknownError
    end
  end

  # At the time of writing, this only works in Chrome.
  if Capybara.current_driver == :chrome
    c.after(:step) do
      # Log errors / warnings from the JS console to aid debugging flaky tests.
      # In the future, we could start marking tests having JS errors as failed.
      errors = page.driver.browser.logs.get(:browser)
      if errors.present?
        errors.each do |error|
          warn "[JS] #{error.level}"
          warn error.message
        end
      end
    end
  end
end
