# frozen_string_literal: true

require 'spec_helper'

describe Course::NavigationDrawer, type: :component do
  subject(:component) { described_class.new }

  let(:table_of_contents) do
    Navigation::TableOfContents.new.tap do |toc|
      toc.with_section(text: 'Week 1', link: {href: '/week-1'})
    end
  end

  it 'renders the drawer around its content slots' do
    render_inline(component) do |drawer|
      drawer.with_main_content { 'Main content' }
      drawer.with_overview_link { '<a href="/overview">Go to overview</a>'.html_safe }
      drawer.with_navigation(component: table_of_contents)
    end

    expect(page).to have_css('.x-drawer > .x-drawer-toggle#course-nav-drawer.peer', visible: :all)
    expect(page).to have_css('.x-drawer > .x-drawer-content', text: 'Main content')
    expect(page).to have_css('.x-drawer > .x-drawer-side')
    expect(page).to have_css('.x-drawer-side .x-drawer-overlay[for="course-nav-drawer"]')
    expect(page).to have_css('.x-drawer-content > .sticky > .x-drawer-button[for="course-nav-drawer"]')
    expect(page).to have_css('.x-drawer-content > .x-drawer-button[for="course-nav-drawer"]')
    expect(page.find('.x-drawer-side', visible: :all)[:class]).to include('top-navbar', 'h-auto', 'bottom-0')
    side = page.find(".x-drawer-side > div[aria-label='Toggle navigation']")
    expect(side).to have_link('Go to overview', href: '/overview')
    expect(side).to have_link('Week 1', href: '/week-1')
  end

  it 'renders the progress above the navigation' do
    render_inline(component) do |drawer|
      drawer.with_main_content { 'Main content' }
      drawer.with_course_progress { '<div id="progress">Progress</div>'.html_safe }
      drawer.with_navigation(component: table_of_contents)
    end

    navigation = page.find(".x-drawer-side > div[aria-label='Toggle navigation']")
    expect(navigation).to have_css('div#progress:first-child', text: 'Progress')
    expect(navigation).to have_css('div#progress + nav')
  end
end
