# frozen_string_literal: true

require 'spec_helper'

describe Global::Carousel, type: :component do
  subject(:component) { described_class.new(label: 'Our teachers') }

  def render_with_items(count)
    render_inline(component) do |carousel|
      count.times {|i| carousel.with_item { "Item #{i + 1}" } }
    end
  end

  it 'renders a labelled carousel region' do
    render_with_items(3)

    expect(page).to have_css '[role="region"][aria-roledescription="Carousel"][aria-label="Our teachers"]'
  end

  it 'renders each item' do
    render_with_items(3)

    expect(page).to have_css '.x-carousel [data-carousel-target="item"]', count: 3
    expect(page).to have_css '[data-carousel-target="item"]', text: 'Item 2'
  end

  it 'renders previous/next buttons beside the items, hidden until the controller knows the page count' do
    render_with_items(3)

    expect(page).to have_css(
      'button[aria-label="Previous"][hidden] + .x-carousel + button[aria-label="Next"][hidden]',
      visible: :all
    )
  end

  it 'renders nothing without items' do
    render_with_items(0)

    expect(page).to have_no_css '[role="region"]'
  end

  it 'grows the items to fill the row' do
    render_with_items(2)

    expect(page).to have_css '[data-carousel-target="item"].grow', count: 2
  end

  context 'with small items' do
    subject(:component) { described_class.new(label: 'Our teachers', size: :sm) }

    it 'renders each item, keeping its width when there are few' do
      render_with_items(2)

      expect(page).to have_css '[data-carousel-target="item"]', count: 2
      expect(page).to have_no_css '[data-carousel-target="item"].grow'
    end
  end
end
