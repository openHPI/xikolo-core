# frozen_string_literal: true

module Timing
  Given(/^I wait for (\d+) seconds?$/) do |n|
    sleep(n.to_i)
  end

  When(/^I wait for (\d+) seconds?$/) do |n|
    sleep(n.to_i)
  end
end

Gurke.config.include Timing
