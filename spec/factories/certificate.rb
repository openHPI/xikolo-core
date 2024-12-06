# frozen_string_literal: true

require 'xikolo/common/rspec'

FactoryBot.define do
  factory 'certificate:root', class: Hash do
    open_badge_templates_url { '/open_badge_templates/{course_id}' }

    initialize_with { attributes.as_json }
  end

  factory 'certificate:roa', class: Hash do
    id { SecureRandom.uuid }
    user_id
    course_id
    template_id { SecureRandom.uuid }
    type { 'Xikolo::Certificate::RecordOfAchievement' }
    verification { 'xinif-mehon-nuhuh-lirom-bapal' }

    verification_url { "/verification?code=#{verification}" }
    open_badge_url { "/open_badges?course_id=#{course_id}&user_id=#{user_id}" }

    initialize_with { attributes.as_json }
  end

  factory 'certificate:roa:verification', class: Hash do
    type { 'RecordOfAchievement' }
    verification { 'xinif-mehon-nuhuh-lirom-bapal' }
    score do
      {
        'points' => 0,
        'max_points' => 0,
        'percent' => 0,
      }
    end
    issued_at { '2019-09-01' }
    user do
      {
        'id' => user_id,
        'name' => 'John Smith',
        'email' => 'john.smith42@example.com',
        'date_of_birth' => nil,
      }
    end
    course_id

    transient do
      user_id { '00000001-3100-4444-9999-000000000142' }
    end

    initialize_with { attributes.as_json }
  end

  factory :certificate_template, class: 'Certificate::Template' do
    association :course
    file_uri { 's3://xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf' }
    certificate_type { 'RecordOfAchievement' }
    dynamic_content do
      <<-DYNAMIC_CONTENT
      <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
          <g id="Dynamic-data">
            <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04"  font-size="21.6" font-family="OpenSansSemibold" text-anchor="start" xml:space="preserve">##NAME##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="174.26"  font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##EMAIL##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="197.26"  font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##AFFILIATION##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="215.138"  font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##BIRTHDAY##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="432.37"  font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##GRADE##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="453.37"  font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##TOP##</text>
          </g>
        </svg>
      DYNAMIC_CONTENT
    end

    trait :fixed do
      association :course, id: '00000001-3300-4444-9999-000000000001'
      file_uri { 's3://xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf' }
    end

    trait :certificate do
      certificate_type { 'Certificate' }
    end

    trait :roa do
      certificate_type { 'RecordOfAchievement' }
    end

    trait :cop do
      certificate_type { 'ConfirmationOfParticipation' }
    end

    trait :tor do
      certificate_type { 'TranscriptOfRecords' }
    end

    trait :invalid_xml do
      dynamic_content do
        <<-XML
        <?xml version="1.0" encoding="utf-8"?>
          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
          <svg version="1.1" baseProfile="basic" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
            <g id="Dynamic data">
              <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04"  font-size="21.6" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">##NAME##</text>
              <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="174.26"  font-size="14.4" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">##EMAIL##</text>
              <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="197.26"  font-size="14.4" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">##AFFILIATION##</text>
              <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="215.138"  font-size="14.4" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">##BIRTHDAY##</text>
              <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="432.37"  font-size="8" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">##GRADE##</text>
              <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="453.37"  font-size="8" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">##TOP##</text>
            </g>
          <svg>
        XML
      end
    end

    trait :missing_fonts do
      dynamic_content do
        <<-XML
        <?xml version="1.0" encoding="utf-8"?>
          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
          <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
            <g id="Dynamic-data">
              <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04"  font-size="21.6" font-family="NeoSansMedium" text-anchor="start" xml:space="preserve">##NAME##</text>
            </g>
          </svg>
        XML
      end
    end

    trait :invalid_schema do
      dynamic_content do
        <<-XML
        <?xml version="1.0" encoding="utf-8"?>
          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
          <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
            <g id="Dynamic-data">
              <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04"  font-size="21.6" font="OpenSansRegular" text-anchor="left" xml:space="preserve">##NAME##</text>
            </g>
          </svg>
        XML
      end
    end
  end

  # Abstract Certificate::Record factory
  factory :record, class: 'Certificate::Record' do
    association :user
    association :course, records_released: true
    association :template, factory: :certificate_template
  end

  factory :roa, parent: :record, class: 'Certificate::RecordOfAchievement' do
    template do
      association :certificate_template, certificate_type: 'RecordOfAchievement', course:
    end
  end

  factory :cop, parent: :record, class: 'Certificate::ConfirmationOfParticipation' do
    template do
      association :certificate_template, certificate_type: 'ConfirmationOfParticipation', course:
    end
  end

  factory :certificate, parent: :record, class: 'Certificate::Certificate' do
    template do
      association :certificate_template, certificate_type: 'Certificate', course:
    end
  end

  factory :open_badge, class: 'Certificate::OpenBadge' do
    association :record, factory: :roa
    association :open_badge_template
  end

  factory :open_badge_v2, class: 'Certificate::V2::OpenBadge' do
    association :record, factory: :roa
    association :open_badge_template

    trait :baked do
      file_uri { 's3://xikolo-certificate/openbadage/25cybhs1xuULc2at3/1YLgUE6KPhaxfpGSZ.png' }
      assertion do
        {
          id: 'http://localhost:3000/courses/open-badges/openbadges/v2/assertion/d0c104cc-2f60-4b39-b2af-f3705cb058dc',
          type: 'Assertion',
          badge: 'http://localhost:3000/courses/open-badges/openbadges/v2/class.json',
          '@context': 'https://w3id.org/openbadges/v2',
          evidence: 'http://localhost:3000/verify/xifem-zutok-nynyn-nubin-ketyz',
          issuedOn: '2019-09-09T00:00:00Z',
          recipient: {
            type: 'email',
            hashed: true,
            identity: 'sha256$89afb9f04c2395d92a2634e32de9b28f18b610ec9f3045eb5de3cb461da57a6d',
          },
          verification: {
            type: 'signed',
            creator: 'http://localhost:3000/openbadges/v2/public_key.json',
          },
        }.as_json
      end
    end
  end

  factory :open_badge_template, class: 'Certificate::OpenBadgeTemplate' do
    association :course
    file_uri { 's3://xikolo-certificate/openbadge_templates/1YLgUE6KPhaxfpGSZ.png' }

    trait :full do
      name { 'Custom badge name' }
      description { 'Custom badge description' }
    end
  end
end
