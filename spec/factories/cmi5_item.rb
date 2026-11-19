# frozen_string_literal: true

FactoryBot.define do
  factory :cmi5_item, class: 'Cmi5::Item' do
    package { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/dummy_cmi5_exercise.zip')) }
  end
end
