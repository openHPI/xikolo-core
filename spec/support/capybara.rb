# frozen_string_literal: true

require 'capybara/rspec'

def headless?
  %w[0 n no off false].exclude?(ENV.fetch('HEADLESS', '1').downcase)
end

BROWSER_DEFAULT_DIMENSIONS = {
  width: 1024,
  height: 768,
}.freeze

Capybara.register_driver :firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--window-size=#{BROWSER_DEFAULT_DIMENSIONS[:width]},#{BROWSER_DEFAULT_DIMENSIONS[:height]}")
  options.add_argument('-headless') if headless?

  options.add_preference('intl.accept_languages', 'en')

  Capybara::Selenium::Driver.new app, browser: :firefox, options:
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--window-size=#{BROWSER_DEFAULT_DIMENSIONS[:width]},#{BROWSER_DEFAULT_DIMENSIONS[:height]}")
  options.add_argument('--headless=new') if headless?
  options.add_argument('--incognito')
  options.add_argument('--disable-site-isolation-trials')
  options.add_argument('--disable-search-engine-choice-screen')

  options.add_preference('intl.accept_languages', 'en')

  Capybara::Selenium::Driver.new app, browser: :chrome, options:
end

case ENV.fetch('BROWSER', 'chrome')
  when /^(firefox|iceweasel|gecko)$/i
    Capybara.default_driver = :firefox
  when /^chrom(e|ium)$/i
    Capybara.default_driver = :chrome
end

Capybara.configure do |config|
  # Some of our form fields are visually hidden and replaced by "prettier" alternatives.
  config.automatic_label_click = true
end

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :component

  # Include Capybara matchers for use with fragments. If not included,
  # expectations such as `have_link` would use RSpecs generic "has"
  # matcher, which does not correctly pass keyword arguments to
  # "has_link?".
  config.include Capybara::RSpecMatchers, type: :request

  config.before(type: :feature) do
    # Reset browser size to desktop view
    Capybara.page.driver.browser.manage.window.resize_to(
      BROWSER_DEFAULT_DIMENSIONS[:width].to_s,
      BROWSER_DEFAULT_DIMENSIONS[:height].to_s
    )
  end
end
