# frozen_string_literal: true

module Abstract
  ##
  # A base class for all controllers handling AJAX requests
  class AjaxController < ::ApplicationController
    rescue_from Status::Unauthorized do
      render status: :forbidden, json: {errors: 'forbidden'}
    end

    private

    def ensure_logged_in
      return true if current_user.logged_in?

      head :forbidden
    end

    def fetch_metric(name:, **params)
      return lanalytics_api.rel(:metric).get({**params, name:}) if metrics_available?(name)

      Restify::Promise.fulfilled(nil)
    end

    def metrics_available?(*names)
      names.map(&:underscore).all? {|name| available_metrics.include?(name) }
    end

    def available_metrics
      @available_metrics ||= begin
        metrics_list = lanalytics_api.rel(:metrics).get.value!
        metrics_list.select {|metric| metric['available'] }.pluck('name')
      end
    end

    def lanalytics_api
      @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
    end

    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end
  end
end
