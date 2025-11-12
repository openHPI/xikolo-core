# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/abuse_report', class: 'PinboardService::AbuseReport' do
    user_id { SecureRandom.uuid }
    reportable_type { 'PinboardService::Question' }
    association :reportable, factory: :'pinboard_service/question', strategy: :create
    course_id { SecureRandom.uuid }
  end
end
