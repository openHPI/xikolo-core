# frozen_string_literal: true

require 'spec_helper'

describe Global::FilterBar::Controls, type: :component do
  subject(:component) do
    described_class.new('/', '#content', '#loading', filters, show_overview:)
  end

  let(:show_overview) { false }
  let(:filter_class) { Struct.new(:key, :title, :options, :selected) }
  let(:filters) { [filter_class.new(:status, 'Status', %w[active inactive], 'active')] }

  context 'when show_overview is false' do
    it 'hides the results overview summary' do
      render_inline(component)
      expect(rendered_content).to have_no_text I18n.t(:'components.filter_bar.filter.adjust')
    end
  end

  context 'when show_overview is true' do
    let(:show_overview) { true }

    it 'shows the results overview summary' do
      render_inline(component)
      expect(rendered_content).to have_text I18n.t(:'components.filter_bar.filter.adjust')
    end
  end
end
