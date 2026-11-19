# frozen_string_literal: true

require 'spec_helper'
describe Global::Accordion, type: :component do
  it 'renders header + footer + content when slots are set' do
    render_inline(described_class.new) do |accordion|
      accordion.with_section('Label', 'some-id', expanded: true) do |section|
        section.with_header { '<span class="badge">pts</span>'.html_safe }
        section.with_footer { '<div class="nav">nav</div>'.html_safe }
        'BODY-HERE'
      end
    end
    expect(page).to have_css('details[open] > summary[aria-controls="some-id"] .badge', text: 'pts')
    expect(page).to have_css('#some-id .nav', text: 'nav')
    expect(page).to have_css('#some-id', text: 'BODY-HERE')
  end

  it 'renders content only when no slots are set (e.g. home page)' do
    render_inline(described_class.new(headline: 'Headline')) do |accordion|
      accordion.with_section('Item 1', 'ID1') do
        'Some text content'
      end
    end
    expect(page).to have_css('details:not([open]) > summary', text: 'Item 1')
    expect(page).to have_css('#ID1', text: 'Some text content', visible: :hidden)
  end

  it 'renders a locked section that cannot be opened' do
    render_inline(described_class.new) do |accordion|
      accordion.with_section('Locked', 'locked-id', expanded: true, locked: true) do
        'HIDDEN-BODY'
      end
    end
    expect(page).to have_css('[data-testid="accordion-section"]', text: 'Locked')
    expect(page).to have_no_css('details, summary, #locked-id')
    expect(page).to have_no_text(:all, 'HIDDEN-BODY')
  end
end
