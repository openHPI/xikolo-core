# frozen_string_literal: true

FactoryBot.define do
  sequence(:uuid) do |n|
    UUID4.new(format('00000000-0000-4000-b000-%012d', n))
  end
end
