# frozen_string_literal: true

require 'capybara/rspec'

logger = Selenium::WebDriver.logger
logger.level = :debug
logger.output = 'log/selenium.log'

def headless?
  %w[0 n no off false].exclude?(ENV.fetch('HEADLESS', '1').downcase)
end

Capybara.register_driver :firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument('--window-size=1280,1024')
  options.add_argument('-headless') if headless?

  options.add_preference('intl.accept_languages', 'en')

  Capybara::Selenium::Driver.new app, browser: :firefox, options:
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
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')

  if headless?
    options.add_argument('--headless=new')
  end

  options.add_argument('--disable-search-engine-choice-screen')
  options.add_argument('--disable-site-isolation-trials')
  options.add_argument('--window-size=1280,1024')

  options.add_preference('download.prompt_for_download', false)
  options.add_preference('intl.accept_languages', 'en')
  options.add_preference('plugins.plugins_disabled', ['Chrome PDF Viewer'])

  Capybara::Selenium::Driver.new app, browser: :chrome, options:
end

case ENV.fetch('BROWSER', 'chrome')
  when /^(firefox|iceweasel|gecko)$/i
    Capybara.default_driver = :firefox
  when /^chrom(e|ium)$/i
    Capybara.default_driver = :chrome
end

Capybara.configure do |config|
  # Some of our form fields are visually hidden and replaced by
  # "prettier" alternatives. When set to true, capybara will attempt to
  # click the associated <label> element if the checkbox/radio button
  # are non-visible.
  config.automatic_label_click = true
end

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :component

  # Include Capybara matchers for use with fragments. If not included,
  # expectations such as `have_link` would use RSpecs generic "has"
  # matcher, which does not correctly pass keyword arguments to
  # "has_link?".
  config.include Capybara::RSpecMatchers, type: :request

  config.before(type: :system) do
    # Always run with a full browser to ensure the page behavior is like
    # a real browser.
    driven_by(Capybara.default_driver)

    # Reset browser size to desktop view
    Capybara.page.driver.browser.manage.window.resize_to(1280, 1024)

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
end
