# frozen_string_literal: true

class RootController < ApplicationController
  respond_to :json

  def index
    respond_with routes
  end

  private

  def routes
    {
      user_tests_url: user_tests_rfc6570,
      user_test_url: user_test_rfc6570,
      trials_url: trials_rfc6570,
      trial_url: trial_rfc6570,
      test_groups_url: test_groups_rfc6570,
      test_group_url: test_group_rfc6570,
      metrics_url: metrics_rfc6570,
      metric_url: metric_rfc6570,
      filters_url: filters_rfc6570,
      filter_url: filter_rfc6570,
      user_assignments_url: user_assignments_rfc6570,
      system_info_url: system_info_rfc6570,
    }
  end
end
