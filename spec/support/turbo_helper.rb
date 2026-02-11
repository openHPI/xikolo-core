# frozen_string_literal: true

module TurboHelper
  # Wait for Turbo Drive to finish navigation
  # Turbo sets data-turbo-busy="true" on <html> during navigation
  # This method only waits if Turbo is actually busy, making it faster
  def wait_for_turbo_idle(max_wait: 3)
    selector = 'html[aria-busy="true"], turbo-frame[aria-busy="true"]'
    # Only wait if Turbo is currently busy (optimization: skip wait if already idle)
    if page.has_css?(selector, wait: 0.3) # wait a little for the JS to fire
      page.has_no_css?(selector, wait: max_wait)
    end
  end
end

RSpec.configure do |config|
  config.include TurboHelper, type: :system
end
