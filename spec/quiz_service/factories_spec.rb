# frozen_string_literal: true

require 'spec_helper'

FactoryBot.factories.filter {|factory| factory.name.starts_with?('quiz_service/') }.each do |factory|
  next unless factory.build_class.included_modules.include?(ActiveModel::Validations)

  RSpec.describe "The #{factory.name} factory" do
    it 'is valid' do
      expect(build(factory.name)).to be_valid
    end
  end
end
