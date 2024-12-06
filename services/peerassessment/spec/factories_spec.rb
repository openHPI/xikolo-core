# frozen_string_literal: true

require 'spec_helper'

FactoryBot.factories.each do |factory|
  RSpec.describe "The #{factory.name} factory" do
    it 'is valid' do
      expect(build(factory.name)).to be_valid
    end
  end
end
