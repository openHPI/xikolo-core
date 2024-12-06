# frozen_string_literal: true

FactoryBot.define do
  factory 'news:root', class: Hash do
    current_alerts_url { '/current_alerts' }
    news_index_url { '/news' }
    announcements_url { '/announcements' }
    announcement_url { '/announcements/{id}' }

    initialize_with { attributes.as_json }
  end
end
