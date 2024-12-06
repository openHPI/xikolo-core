# frozen_string_literal: true

require 'active_support/concern'

module DefaultParams
  extend ActiveSupport::Concern

  def process(action, params: {}, **)
    params.reverse_merge!(default_params)
    super
  end

  included do
    let(:default_params) { {} }
  end
end

RSpec.configure do |config|
  config.include DefaultParams, type: :controller
end
