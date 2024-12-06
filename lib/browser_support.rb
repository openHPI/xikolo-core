# frozen_string_literal: true

class BrowserSupport
  def initialize(browser)
    @browser = browser
  end

  ##
  # A browser that we actively discourage using.
  #
  def unsupported?
    return false if @browser.bot?
    return true if @browser.ie?

    @browser.edge? && @browser.version.to_i < 119
  end

  VERSIONS_CONSIDERED_MODERN = {
    chrome: 119,
    edge: 122,
    firefox: 115,
    opera: 107,
    safari: 17,
  }.freeze

  ##
  # A browser that we may not fully support.
  #
  def old?
    return false if @browser.bot?
    return true if @browser.ie?
    return false if firefox_on_ipad? && (@browser.version.to_i > 68)

    VERSIONS_CONSIDERED_MODERN.any? do |browser, minimum|
      @browser.send(:"#{browser}?") && @browser.version.to_i < minimum
    end
  end

  private

  def firefox_on_ipad?
    # Firefox version numbers are different for iOS and
    # the browser gem does not detect iPads with iOS 13 as iPad but Mac.
    # Thus, we check for platform.mac? in combination with webkit? instead.
    @browser.platform.mac? && @browser.webkit? && @browser.firefox?
  end
end
