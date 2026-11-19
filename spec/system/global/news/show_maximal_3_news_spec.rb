# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: Show 3 news at a max', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  it 'shows only the 3 latest news on the homepage' do
    (1..5).each do |i|
      create(:'news_service/news', :global,
        author_id: admin.id,
        show_on_homepage: true,
        publish_at: i.days.ago,
        translations: false)
      NewsService::News.last.translations.create(
        title: "Global News Headline #{i}",
        text: 'To Be, Or Not To Be',
        locale: 'en'
      )
    end

    visit '/'

    (1..3).each do |i|
      expect(page).to have_text "Global News Headline #{i}"
    end
    expect(page).to have_no_text 'Global News Headline 4'
  end
end
