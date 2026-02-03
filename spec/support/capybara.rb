# frozen_string_literal: true

logger = Selenium::WebDriver.logger
logger.level = :debug
logger.output = 'log/selenium.log'

def headless?
  %w[0 n no off false].exclude?(ENV.fetch('HEADLESS', '1').downcase)
end

def browser
  case ENV.fetch('BROWSER', 'chrome')
    when /^(firefox|iceweasel|gecko)$/i
      :firefox
    when /^chrom(e|ium)$/i
      :chrome
  end
end

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :component

  # Include Capybara matchers for use with fragments. If not included,
  # expectations such as `have_link` would use RSpecs generic "has"
  # matcher, which does not correctly pass keyword arguments to
  # "has_link?".
  config.include Capybara::RSpecMatchers, type: :request

  config.before(type: :system) do
    driven_by(:selenium, using: :"#{'headless_' if headless?}#{browser}")
  end
end
