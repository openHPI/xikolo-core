# frozen_string_literal: true

module WellKnown
  class AppLinksController < ::ApplicationController
    # The Digital Asset Links file for Android App Links verification
    # This route is used by the Android app to verify the website in order to handle deep links
    # The links that can be handled are defined by the app
    # See https://developer.android.com/training/app-links/
    def android
      file = WellKnownFile::GoogleAssetLinks.new

      raise AbstractController::ActionNotFound unless file.configured?

      render json: file.as_json
    end

    # The Association file for iOS Universal Links verification
    # This route is used by the iOS app to verify the website in order to handle deep links
    # The links that can be handled are defined by the website
    # See https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
    def ios
      file = WellKnownFile::AppleAppSiteAssociation.new

      raise AbstractController::ActionNotFound unless file.configured?

      render json: file.as_json
    end
  end
end
