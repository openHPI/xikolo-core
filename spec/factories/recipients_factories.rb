# frozen_string_literal: true

FactoryBot.define do
  factory 'recipient:user', class: 'String' do
    id { generate(:uuid) }

    initialize_with { "urn:x-xikolo:account:user:#{id}" }
  end

  factory 'recipient:group', class: 'String' do
    id { generate(:uuid) }

    initialize_with { "urn:x-xikolo:account:group:#{id}" }
  end
end
