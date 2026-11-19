# frozen_string_literal: true

require 'spec_helper'

describe Global::Accordion, type: :component do
  it 'renders the course details preview' do
    render_preview(:course_details, from: Global::AccordionPreview, params: {lookbook: {display: {}}})

    expect(page).to have_css('details[open] summary', text: 'Lernziele')
    expect(page).to have_css('#learning-goals li', count: 5)
  end

  it 'renders the course overview preview' do
    render_preview(:course_overview, from: Global::AccordionPreview, params: {lookbook: {display: {}}})

    expect(page).to have_css('details[open] summary', text: 'Modul 1')
    expect(page).to have_link('Starten')
    expect(page).to have_css('#module-1 .sr-only', text: 'Abgeschlossen', exact_text: true, count: 2)
    expect(page).to have_css('#module-1 [aria-current="step"]', text: 'Starten')
    expect(page).to have_no_css('#module-2 .sr-only', text: 'Abgeschlossen', exact_text: true, visible: :all)
    expect(page).to have_no_css('#module-3 [aria-current]', visible: :all)
  end

  it 'renders native disclosures with the requested initial state and associated content' do
    render_inline(described_class.new(headline: 'Course details')) do |accordion|
      accordion.with_section('Goals', 'goals', expanded: true) { 'Learning goals' }
      accordion.with_section('Requirements', 'requirements') { 'Certificate requirements' }
    end

    expect(page).to have_text('Course details')
    expect(page).to have_css('details[open] > summary[aria-controls="goals"]', text: 'Goals')
    expect(page).to have_css('#goals', text: 'Learning goals')
    expect(page).to have_css('details:not([open]) > summary[aria-controls="requirements"]', text: 'Requirements')
    expect(page).to have_css('#requirements', text: 'Certificate requirements', visible: :hidden)
  end

  it 'groups sections within each accordion independently' do
    groups = Array.new(2) do
      render_inline(described_class.new) do |accordion|
        accordion.with_section('First', 'first') { 'First content' }
        accordion.with_section('Second', 'second') { 'Second content' }
      end

      page.all('details', visible: :all).map { it[:name] }
    end

    expect(groups.first.uniq.size).to eq(1)
    expect(groups.last.uniq.size).to eq(1)
    expect(groups.first.first).to be_present
    expect(groups.first.first).not_to eq(groups.last.first)
  end

  it 'allows section metadata alongside the title' do
    render_inline(described_class.new) do |accordion|
      accordion.with_section('Module 1', 'module-1') do |section|
        section.with_header_detail { '2 / 5 completed · 45 min.' }
        'Lessons'
      end
    end

    expect(page).to have_css('summary', text: 'Module 1 2 / 5 completed · 45 min.', normalize_ws: true)
    expect(page).to have_css('#module-1', text: 'Lessons', visible: :hidden)
  end
end
