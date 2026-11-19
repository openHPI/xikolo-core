# frozen_string_literal: true

require 'spec_helper'

describe PaginationRenderer do
  subject(:pagination) do
    # Implement the abstract url() method, mirroring how LinkRenderer
    # is always used with a routing context.
    Class.new(described_class) do
      def url(page) = "/items?page=#{page}"
    end.new
  end

  let(:current_page) { 3 }
  let(:total_pages)  { 5 }
  let(:collection) do
    instance_double(
      WillPaginate::Collection,
      current_page: current_page,
      total_pages:  total_pages
    )
  end

  before do
    # Bypass LinkRenderer#prepare, which requires a full ActionView context.
    pagination.instance_variable_set(:@collection, collection)
    pagination.instance_variable_set(:@options, {param_name: :page})
  end

  describe '#html_container' do
    subject(:html) { pagination.send(:html_container, '<li>x</li>') }

    it 'wraps content in a <ul>' do
      expect(html).to match(%r{<ul[^>]*>.*</ul>}m)
    end
  end

  describe '#page_number' do
    context 'when the page is the current page' do
      subject(:html) { pagination.send(:page_number, current_page) }

      it 'renders a <li> containing a <span> (not a link)' do
        expect(html).to match(%r{<li[^>]*>.*<span[^>]*>.*</span>.*</li>}m)
        expect(html).not_to include('<a ')
      end

      it 'sets aria-current="page"' do
        expect(html).to include('aria-current="page"')
      end

      it 'displays the page number' do
        expect(html).to include(current_page.to_s)
      end
    end

    context 'when the page is not the current page' do
      subject(:html) { pagination.send(:page_number, current_page + 1) }

      it 'renders a <li> containing an <a> link' do
        expect(html).to match(%r{<li[^>]*>.*<a [^>]*href[^>]*>.*</a>.*</li>}m)
      end

      it 'links to the correct page URL' do
        expect(html).to include("/items?page=#{current_page + 1}")
      end

      it 'does not set aria-current' do
        expect(html).not_to include('aria-current')
      end
    end
  end

  describe '#gap' do
    subject(:html) { pagination.send(:gap) }

    it 'renders a <li> containing a disabled <button>' do
      expect(html).to match(%r{<li[^>]*>.*<button[^>]*disabled[^>]*>.*</button>.*</li>}m)
    end

    it 'displays the ellipsis character' do
      expect(html).to include('…')
    end

    it 'is hidden from assistive technology' do
      expect(html).to include('aria-hidden="true"')
    end
  end

  describe '#previous_or_next_page' do
    context 'when a target page exists (enabled state)' do
      subject(:html) { pagination.send(:previous_or_next_page, 2, 'Previous', '') }

      it 'renders a link to the target page' do
        expect(html).to include('<a ')
        expect(html).to include('/items?page=2')
      end

      it 'is not disabled' do
        expect(html).not_to include('disabled')
      end
    end

    context 'when no target page exists (disabled state)' do
      subject(:html) { pagination.send(:previous_or_next_page, false, 'Previous', '') }

      it 'renders a disabled <button> instead of a link' do
        expect(html).to match(/<button[^>]*disabled/)
        expect(html).not_to include('<a ')
      end

      it 'sets aria-disabled' do
        expect(html).to include('aria-disabled="true"')
      end
    end
  end

  describe '#previous_page' do
    context 'when on a middle page' do
      subject(:html) { pagination.send(:previous_page) }

      it 'renders an enabled link to the preceding page' do
        expect(html).to include('/items?page=2')
        expect(html).not_to include('disabled')
      end

      it 'includes the previous-page label' do
        expect(html).to include('Previous')
      end
    end

    context 'when on the first page' do
      subject(:html) { pagination.send(:previous_page) }

      let(:current_page) { 1 }

      it 'renders a disabled button' do
        expect(html).to match(/<button[^>]*disabled/)
      end
    end
  end

  describe '#next_page' do
    context 'when on a middle page' do
      subject(:html) { pagination.send(:next_page) }

      it 'renders an enabled link to the following page' do
        expect(html).to include('/items?page=4')
        expect(html).not_to include('disabled')
      end

      it 'includes the next-page label' do
        expect(html).to include('Next')
      end
    end

    context 'when on the last page' do
      subject(:html) { pagination.send(:next_page) }

      let(:current_page) { total_pages }

      it 'renders a disabled button' do
        expect(html).to match(/<button[^>]*disabled/)
      end
    end
  end
end
