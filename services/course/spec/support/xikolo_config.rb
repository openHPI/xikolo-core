# frozen_string_literal: true

module SetXikoloConfig
  # A helper to write Xikolo.config options for the duration of a single test.
  #
  # This takes a snippet of YAML and merges it into the default configuration.
  # This approach ensures that tests can only write options in a way that is
  # possible in YAML files (e.g. hashes usually have string keys).
  #
  # This works best with Ruby's squiggly heredoc syntax:
  #   xi_config <<~YML
  #     feature:
  #       key1: value1
  #       key2: value2
  #   YML
  #
  def xi_config(yaml)
    Xikolo.config.merge YAML.safe_load yaml
  end
end

RSpec.configure do |config|
  config.include SetXikoloConfig

  config.before do
    # Reset the config after every test case so that modifying the config for one scenario
    # does not affect following scenarios (which can lead to nasty order dependencies).
    Xikolo::Config.reload
  end
end