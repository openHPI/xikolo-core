# frozen_string_literal: true

require 'typhoeus'
require 'json'

# The configuration for Successfactors API course provider must
# include the following options:
#
# client_id:           name of the Successfactors instance
# client_secret:       the Oauth secret
# base_url:            URL of the Successfactors instance
# user_id:             id of the Successfactors API user
# company_id:          id of the Successfactors instance customer
# provider_id:         id of the Successfactors OCN provider
# launch_url_template: URI template for launching the course

class Successfactors::Adapter
  CONFIG_KEYS = %w[
    client_id
    client_secret
    base_url
    user_id
    company_id
    provider_id
    launch_url_template
  ].freeze

  def initialize(name, course, config)
    @name = name
    @course = course
    @config = config

    config_diff = CONFIG_KEYS - @config.keys
    raise Successfactors::ConfigError.new(config_diff) unless config_valid?
  end

  def sync
    return unless @course

    data = {
      ocnCourses: [Successfactors::Course.new(@course, @config).as_ocn_data],
    }

    api.post_courses data.to_json
  end

  private

  def api
    @api ||= Successfactors::API.new(@name, @config)
  end

  def config_valid?
    return true if @config.keys.to_set == CONFIG_KEYS.to_set

    false
  end
end

class Successfactors::ConfigError < StandardError
  def initialize(config_diff)
    super()
    @config_diff = config_diff
  end

  def message
    'SuccessFactors config not sufficient ' \
      "(missing options: #{@config_diff.join(', ')})"
  end
end
