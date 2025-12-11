# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/additional_quiz_attempt' do
    user_id { '00000000-0000-4444-9999-000000000001' }
    quiz_id { '00000000-0000-4444-9999-000000000001' }
    count { 2 }
  end
end
