# frozen_string_literal: true

require 'uri'

# Track external sites linking to our platform
#
# This concern can be used in public-facing HTML controllers to track where
# users came from when clicking on links to our platform. This information is
# taken from the HTTP Referer header and enriched with more request data. It is
# then sent to the lanalytics service for aggregation and calculation of stats.
module TracksReferrers
  extend ActiveSupport::Concern

  included do
    after_action :track_referrer
  end

  private

  def track_referrer
    # Logo requests (from emails) should not be considered as real clicks, so
    # we ignore these.
    return if params[:logo] == 'true'

    # If there are no parameters worth tracking (such as campaign or user ID),
    # we are already done.
    return if tracking_payload.empty?

    # Now, if we have data to store, enrich the payload with server-side
    # metadata, such as date, URL and context information.
    # Finally, send it off to lanalytics.
    Msgr.publish(enriched_payload.as_json, to: 'xikolo.web.referrer')
  end

  def tracking_payload
    @tracking_payload ||= {
      referrer: normalized_referrer,
      tracking_external_link: params[:url],
      tracking_campaign: params[:tracking_campaign],
      tracking_id: params[:tracking_id],
      tracking_course_id: params[:tracking_course_id],
      tracking_type: params[:tracking_type],
      user_id: user_id_from_tracking_params,
    }.compact
  end

  def enriched_payload
    {
      # Unless already provided through request params, we can try to fallback
      # to the logged-in users' ID.
      user_id: current_user.logged_in? ? current_user.id : nil,

      # Merge all params from the request
      **tracking_payload,

      # Additional attributes that can be determined on the server side
      course_id: promises[:course]&.id,
      referrer_page: request.original_url,
      created_at: DateTime.now,
    }.compact
  end

  def normalized_referrer
    return if request.referer.blank?

    url = URI.parse(request.referer)

    # Invalid hosts are ignored (URIs like http/foobaz do not raise a parse error)
    raise URI::InvalidURIError if url.host.nil?

    # Internal referrers are ignored
    return if Xikolo.base_url.host.start_with?(url.host)

    # For external referrers, we re-build the referrer without the protocol
    "#{url.host}#{url.path}#{url.query ? '?' : ''}#{url.query}"
  rescue URI::InvalidURIError
    # Ignore invalid URLs (or parse errors)
  end

  def user_id_from_tracking_params
    return if current_user.logged_in?

    UUID4.try_convert params[:tracking_user]
  end
end
