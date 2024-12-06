# frozen_string_literal: true

require 'typhoeus'

module PatchCollectNetworkFailures
  def execute_callbacks
    if response&.code&.zero?
      Xikolo.metrics.write(
        'curl_errors',
        tags: {
          method: options[:method],
          return_code: response.return_code,
          return_message: response.return_message,
        },
        values: {
          appconnect_time: response.appconnect_time,
          base_url: response.request.base_url.to_s,
          connect_time: response.connect_time,
          effective_url: response.effective_url,
          namelookup_time: response.namelookup_time,
          pretransfer_time: response.pretransfer_time,
          primary_ip: response.primary_ip,
          redirect_count: response.redirect_count,
          redirect_time: response.redirect_time,
          starttransfer_time: response.starttransfer_time,
          total_time: response.total_time,
        }
      )
    end

    super
  end
end

Typhoeus::Request.prepend PatchCollectNetworkFailures
