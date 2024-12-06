# frozen_string_literal: true

require 'spec_helper'

describe Navigation::TableOfContents, type: :component do
  subject(:component) do
    described_class.new
  end

  context 'provided with sections' do
    it 'renders sections' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'})
        toc.with_section(text: 'Section 2', link: {href: '/section_2'})
      end

      # sections should be rendered in a single list
      expect(page).to have_css('ul', count: 1)

      expect(page).to have_link('Section 1', href: '/section_1')
      expect(page).to have_link('Section 2', href: '/section_2')
    end
  end

  context 'provided with units' do
    it 'renders sections and its units' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}) do |section|
          section.with_segment_unit(text: 'Unit 1', link: {href: '/unit_1'})
          section.with_segment_unit(text: 'Unit 2', link: {href: '/unit_2'})
        end
      end

      # units are rendered in a separate list
      expect(page).to have_css('ul', count: 2)

      expect(page).to have_link('Section 1', href: '/section_1')
      expect(page).to have_link('Unit 1', href: '/unit_1')
      expect(page).to have_link('Unit 2', href: '/unit_2')
    end
  end

  context 'provided with sub sections' do
    it 'renders sections and its sub sections' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}) do |section|
          section.with_segment_section(text: 'Sub Section', link: {href: '/sub_section'})
        end
      end

      # sub sections are rendered in a separate list
      expect(page).to have_css('ul', count: 2)

      expect(page).to have_link('Section 1', href: '/section_1')
      expect(page).to have_link('Sub Section', href: '/sub_section')
    end
  end
end
