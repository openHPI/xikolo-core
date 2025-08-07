# frozen_string_literal: true

require 'spec_helper'

describe Pinboard::ReportButton, type: :component do
  subject(:component) { described_class.new(path: path) }

  let(:path) { '/report' }

  describe '#render' do
    before { render_inline(component) }

    it 'renders a link to the given path with the default I18n label' do
      expect(page).to have_link('report', href: path)
    end

    it 'includes the data-confirm attribute with I18n default' do
      expect(page).to have_css("a[data-confirm='Are you sure you want to report this content?']")
    end

    it 'includes the I18n default tooltip in the data-tooltip attribute' do
      link = page.find_link('report')
      expect(link[:'data-tooltip']).to eq('Report inappropriate content')
    end

    it 'has a confirm dialog text on click' do
      link = page.find_link('report')
      expect(link[:'data-confirm']).to be_present
    end
  end
end
