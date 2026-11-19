# frozen_string_literal: true

require 'spec_helper'

describe Course::BottomBar, type: :component do
  subject(:component) { described_class.new }

  let(:navigation) { Course::BottomNavigation.new(next_link:) }
  let(:next_link) { {url: '/learn/example/items/next', title: 'Practice', icon: 'text'} }

  it 'does not render an empty bar or reserve space' do
    bar = component
    render_in_view_context do
      safe_join([render(bar), content_for(:bottom_navigation_spacer)])
    end

    expect(page).to have_no_css('nav')
    expect(page).to have_no_css('[aria-hidden="true"]')
  end

  it 'does not render when the navigation has no items' do
    render_inline(component) do |bar|
      bar.with_navigation(component: Course::BottomNavigation.new)
    end

    expect(page).to have_no_css('nav')
  end

  it 'renders navigation in one fixed bar with a spacer' do
    bar = component
    links = navigation
    render_in_view_context do
      output = render(bar) { it.with_navigation(component: links) }
      safe_join([output, content_for(:bottom_navigation_spacer)])
    end

    expect(page).to have_css('nav[aria-label="Course actions"]', count: 1)
    expect(page).to have_link('Next', href: next_link[:url])
    expect(page).to have_css('div[aria-hidden="true"]')
  end

  it 'renders an action without neighboring items' do
    render_inline(component) { it.with_primary_action { '<button type="submit" form="quiz_form">Submit</button>'.html_safe } }

    expect(page).to have_css('nav button[form="quiz_form"]', text: 'Submit')
  end

  it 'composes navigation and an action without nesting bars' do
    render_inline(component) do |bar|
      bar.with_navigation(component: navigation)
      bar.with_primary_action { '<button>Submit</button>'.html_safe }
    end

    expect(page).to have_css('nav', count: 1)
    expect(page).to have_link('Next')
    expect(page).to have_button('Submit')
  end
end
