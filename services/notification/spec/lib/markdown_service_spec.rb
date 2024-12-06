# frozen_string_literal: true

require 'spec_helper'

describe MarkdownService, type: :lib do
  let(:text) { 'Click on https://www.example.com to find eternal youth' }

  it 'linkifies automatically links' do
    expect(MarkdownService.render_html(text)).to eq \
      "<p>Click on <a href=\"https://www.example.com\">https://www.example.com</a> to find eternal youth</p>\n"
  end
end
