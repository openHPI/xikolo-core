# frozen_string_literal: true

require 'spec_helper'

describe Home::Podcast, type: :component do
  subject(:component) do
    described_class.new(
      'Foo Knowledge Podcast',
      podcasts: [
        {title: 'Spotify', icon: 'spotify', link: 'https://www.example.com/spotify'},
        {title: 'Apple', icon: 'podcast', link: 'https://www.example.com/apple'},
      ],
      call_to_action: {link: '/'}
    )
  end

  it 'renders the title and buttons with links' do
    render_inline(component)

    expect(page).to have_content 'Foo Knowledge Podcast'
    expect(page).to have_link('Spotify', href: 'https://www.example.com/spotify')
    expect(page).to have_link('Apple', href: 'https://www.example.com/apple')
  end
end
