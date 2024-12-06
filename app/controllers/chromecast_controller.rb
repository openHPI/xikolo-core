# frozen_string_literal: true

class ChromecastController < ApplicationController
  before_action do
    # If the SMR is not properly configured, don't render one
    raise AbstractController::ActionNotFound unless Chromecast.configured?
  end

  # Dynamically render a Styled Media Receiver (SMR) CSS stylesheet for Google's Chromecast
  #
  # This allows for some custom styling when using Android apps on the TV via
  # Chromecast. A custom color, logo and background can be set in Xikolo Config.
  #
  # See https://developers.google.com/cast/docs/styled_receiver.
  def stylesheet
    @chromecast_styles = {}.tap do |styles|
      styles[:background] = Chromecast.background_url if Chromecast.background_url
      styles[:logo] = Chromecast.logo_url if Chromecast.logo_url
      styles[:progress_color] = Chromecast.progress_color if Chromecast.progress_color
    end

    render css: 'stylesheet'
  end
end
