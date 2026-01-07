# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/document_localization' do
    sequence(:title) do |i|
      "ein sinnvoller deutscher Titel mit der Nummer #{i}"
    end

    sequence(:description) do |j|
      "Inhalt, Inhalt, noch mehr Inhalt mit der Nummer #{j}"
    end

    id { SecureRandom.uuid }
    file_id { SecureRandom.uuid }
    association :document, factory: :'course_service/document'

    sequence(:revision) do |a|
      "#{a}.1"
    end

    language { 'de' }
    deleted { false }
  end
end
