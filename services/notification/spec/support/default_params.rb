# frozen_string_literal: true

require 'active_support/concern'

module DefaultParams
  extend ActiveSupport::Concern

  included do
    let(:default_params) { {format: 'json'} }
    prepend InstanceMethods
  end

  module InstanceMethods
    def get(action, **)
      process(action, method: 'GET', **)
    end

    def put(action, **)
      process(action, method: 'PUT', **)
    end

    def post(action, **)
      process(action, method: 'POST', **)
    end

    def patch(action, **)
      process(action, method: 'PATCH', **)
    end

    def delete(action, **)
      process(action, method: 'DELETE', **)
    end

    def process(action, params: {}, **kwargs)
      params = default_params.merge(params) if params.is_a?(Hash)

      kwargs[:format] ||= params.delete(:format) if params.key?(:format)

      super
    end
  end
end

RSpec.configure do |config|
  config.include DefaultParams, type: :controller
end
