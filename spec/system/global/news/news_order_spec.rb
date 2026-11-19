# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: Show news ordered by newest first', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    sign_in(user: admin)
  end

  it 'shows the 5 news ordered by publishing date' do
    (1..5).map do |i|
      item = create(:'news_service/news', :global, :published,
        author_id: admin.id,
        show_on_homepage: true,
        publish_at: i.days.ago,
        translations: false)
      item.translations.create(
        title: "Global News Headline #{i}",
        text: 'To Be, Or Not To Be',
        locale: 'en'
      )
      item
    end

    click_on('News')

    newsitems = all('.news_item')
    (1..5).each do |i|
      expect(newsitems[i - 1].find('h3').text).to eq("Global News Headline #{i}")
    end

    newsnavitems = all('ul.news-nav li')
    (1..5).each do |i|
      expect(newsnavitems[i - 1].find('a').text).to eq("Global News Headline #{i}")
    end
  end
end
