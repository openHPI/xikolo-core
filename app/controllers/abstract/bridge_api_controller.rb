# frozen_string_literal: true

module Abstract
  ##
  # A base class for all controllers serving a "Bridge API".
  #
  # Bridge APIs are small dedicated interfaces to external services, some of
  # which are internal, some external. They vary in how they are versioned,
  # consumed, documented and what formats they offer.
  #
  class BridgeAPIController < ActionController::Base # rubocop:disable Rails/ApplicationController
    ##
    # We inherit from ActionController::Base (for compatibility with the
    # responders gem), but have to disable HTML-focused features, in order to
    # get closer to what ActionController::API would give us.

    skip_forgery_protection
  end
end
