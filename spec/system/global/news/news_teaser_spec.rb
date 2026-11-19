# frozen_string_literal: true

require 'spec_helper'

describe 'Global/News: Publish a news with teaser', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    sign_in(user: admin)
  end

  it 'shows a news teaser on the homepage when logged in' do
    create(:'news_service/news', :global, :published,
      author_id: admin.id,
      show_on_homepage: true,
      teaser: 'To Be, Or',
      translations: false).translations.create(
        title: 'Global News Headline',
        text: 'To Be, Or Not To Be',
        teaser: 'To Be, Or',
        locale: 'en'
      )

    visit '/'

    expect(page).to have_text 'Global News Headline'
    expect(page).to have_text 'To Be, Or'
  end

  it 'shows a news teaser on the homepage when logged out' do
    create(:'news_service/news', :global, :published,
      author_id: admin.id,
      show_on_homepage: true,
      teaser: 'To Be, Or',
      translations: false).translations.create(
        title: 'Global News Headline',
        text: 'To Be, Or Not To Be',
        teaser: 'To Be, Or',
        locale: 'en'
      )

    find('[aria-label="Profile menu"]').click
    click_on 'Log out'

    visit '/'

    expect(page).to have_text 'Global News Headline'
    expect(page).to have_text 'To Be, Or'
  end
end
