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
    include LoadsCourseChannels

    before_action :check_primary_email
    before_action :set_default_title
    before_action :sanitize_params

    include ContentSecurityPolicy

    private

    def set_default_title
      set_meta_tags title: I18n.t(:default_title)
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
    # set_page_title('foo') will result in "foo"
    # set_page_title('foo', 'bar') will result in "bar | foo"
    def set_page_title(*parts)
      set_meta_tags title: parts.reverse.join(' | ')
    end

    def check_primary_email
      return unless current_user.feature?('primary_email_suspended')

      add_flash_message(
        :notice,
        I18n.t(:'flash.notice.primary_email_suspended').html_safe
      )
    end

    # Filter out *string* params that include a null-byte,
    # to prevent null-byte injections.
    #
    # The null-byte can be in different encodings:
    # - standard null-bytes (\u0000, \x00),
    # - percent-encoded (%00),
    # - double-encoded (%2500)
    # Based on https://zenn.dev/yamap_dev/articles/640d91cae4c8dd.
    NULL_BYTE_PATTERN = Regexp.union("\u0000", "\x00", '%00', '%2500').freeze
    private_constant :NULL_BYTE_PATTERN

    def sanitize_params
      params.reject! do |_k, value|
        value.is_a?(String) && value.match?(NULL_BYTE_PATTERN)
      end
    end
  end
end
