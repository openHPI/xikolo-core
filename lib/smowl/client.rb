# frozen_string_literal: true

require 'addressable'
require 'restify'

module Smowl
  class Client
    def initialize(base)
      @base = base
    end

    def request(function, params = {})
      Restify.new(
        Addressable::Template.new(@base).expand(function:).to_s
      ).post(
        URI.encode_www_form(params)
      ).then do |resource|
        Response.new(function, resource)
      end.value!
    rescue Restify::NetworkError
      raise ServiceError.new 'Network error when contacting the SMOWL API'
    rescue Restify::ServerError
      raise ServiceError.new 'Server-side error in the SMOWL API'
    end
  end
end
