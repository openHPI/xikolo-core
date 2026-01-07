# frozen_string_literal: true

FactoryBot.define do
  factory :'notification_service/mail_log', class: 'NotificationService::MailLog' do
    user_id { '00000001-aaaa-4444-9999-000000000001' }
    course_id { '00000001-3300-4444-9999-000000000001' }
    news_id { '00000001-3300-4444-9455-000000000001' }
    state { 'success' }
    created_at { '2014-10-13 19:36:52.575' }
  end
end
