# frozen_string_literal: true

if Rails.env.integration?
  module XiIntegration
    class << self
      def hook(*hooks, &block)
        hooks.each do |hook|
          self.hooks[hook] ||= []
          self.hooks[hook] << block
        end
      end

      def invoke(hook, *)
        return unless (hooks = self.hooks[hook])

        hooks.each {|h| h.call(*) }
      end

      def hooks
        @hooks ||= {}
      end
    end
  end

  require 'rack/remote'

  Rack::Remote.register :test_case_setup do |params, env, request|
    Rails.logger.warn "TEST CASE SETUP: #{params['id']}"
    XiIntegration.invoke :test_setup, params, env, request

    nil
  end

  Rack::Remote.register :test_case_teardown do |params, env, request|
    Rails.logger.warn "TEST CASE TEARDOWN: #{params['id']}"
    XiIntegration.invoke :test_teardown, params, env, request

    nil
  end

  # Rails.logger = Logger.new(STDOUT)
end
