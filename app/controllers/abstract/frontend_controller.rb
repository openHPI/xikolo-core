# frozen_string_literal: true

module Abstract
  ##
  # A base class for all controllers rendering a full HTML page
  #
  # It offers a few helper methods such as +set_page_title+ which are useful
  # for most controllers rendering HTML.
  # In addition, it loads a bunch of data necessary to render e.g. the channel
  # menu or site-wide alert messages.
  class FrontendController < ::ApplicationController
    helper LanalyticsHelper

    include LoadsCourseChannels

    before_action :check_primary_email
    before_action :check_app_request
    before_action :set_default_title
    before_action :set_js_data
    before_action :sanitize_params

    include TracksReferrers
    include ContentSecurityPolicy

    private

    def check_app_request
      @in_app = false

      if request.params['in_app'].present? && request.params['in_app'] == 'true'
        @in_app = true
        cookies[:in_app] = '1'
        # redirect to given url but without param, used for sso on mobile
        redirect_to(request.params['redirect_to']) if %w[/auth/who].include? request.params['redirect_to']
      end

      # This is similar to `Xikolo::Middleware::RunContext#app_request?`
      if (request.headers['Accept'] == 'application/vnd.xikolo.v1, application/json') ||
         request.headers['User-Platform'].present? ||
         request.headers['X-User-Platform'].present? ||
         (cookies[:in_app] == '1')
        cookies[:in_app] = '1' unless cookies[:in_app] == '1'
        @in_app = true
      end

      gon.in_app = @in_app
    end

    def set_default_title
      set_page_title I18n.t(:default_title)
    end

    # Configure the <title> tag of the current HTML page
    #
    # Send any category, from top to bottom (generic to special).
    # The method will add the site's name, and then concatenate
    # the arguments, from special to generic, separated by a pipe.
    #
    # This way, multiple tabs will be easy to distinguish for the
    # user, as the most special part of the title will come first.
    #
    # EXAMPLES:
    # set_page_title('foo') will result in "foo | Xikolo"
    # set_page_title('foo', 'bar') will result in "bar | foo | Xikolo"
    def set_page_title(*parts)
      parts.unshift Xikolo.config.site_name

      set_meta_tags title: parts.reverse.join(' | ')
    end

    def check_primary_email
      return unless current_user.feature?('primary_email_suspended')

      add_flash_message(
        :notice,
        I18n.t(:'flash.notice.primary_email_suspended').html_safe
      )
    end

    # Set javascript data for lanalytics and other JS functionality.
    def set_js_data
      if promises.key?(:course)
        gon.course_id = the_course.id
      end

      return if current_user.anonymous?

      gon.env = Rails.env
      gon.user_id = current_user.id

      if ENV['RELEASE_NUMBER'].present?
        gon.build_version = ENV['RELEASE_NUMBER']
      end

      if promises.key?(:course) && defined? the_item
        the_item.then do |item|
          if item.present?
            gon.item_id = item['id']
            gon.section_id = item['section_id']
          end
        end&.value!
      end
    end

    # Filter out *string* params that include a null-byte,
    # to prevent null-byte injections.
    #
    # The null-byte can be in different encodings:
    # - standard null-bytes (\u0000, \x00),
    # - percent-encoded (%00),
    # - double-encoded (%2500)
    # Based on https://zenn.dev/yamap_dev/articles/640d91cae4c8dd.
    NULL_BYTE_CHARS = %W[\u0000 \x00 %00 %2500].freeze
    private_constant :NULL_BYTE_CHARS

    def sanitize_params
      params.reject! do |_k, value|
        value.is_a?(String) && NULL_BYTE_CHARS.any? { value.include? it }
      end
    end
  end
end
