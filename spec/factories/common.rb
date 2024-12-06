# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  sequence :uuid do |n|
    UUID4(format('81e01000-0000-4444-a000-%012d', n))
  end
end
