# frozen_string_literal: true

require 'omniauth'
require 'ruby-saml'
require 'omniauth/strategies/xikolo_saml'

module OmniAuth
  module Strategies
    class HPI < XikoloSAML
      info do
        {
          email: @attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'],
          name: full_name,
          user_name: @attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'],
        }
      end

      def full_name
        [
          @attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'],
          @attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'],
        ].join(' ')
      end
    end
  end
end

OmniAuth.config.add_camelization 'hpi', 'HPI'
