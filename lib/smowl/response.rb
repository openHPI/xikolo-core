# frozen_string_literal: true

module Smowl
  class Response
    def initialize(function, resource)
      @function = function
      @resource = resource
    end

    def success?
      @resource.response.success? && !@resource.key?('error')
    end

    def data
      return unless success?

      # Return *nil* if the function response cannot be resolved.
      @resource.fetch("#{@function}Response", nil)
    end

    def acknowledged?
      return false unless success?

      data && data['ack']
    end
  end
end
