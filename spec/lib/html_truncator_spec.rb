# frozen_string_literal: true

require 'spec_helper'
require 'html_truncator'

describe HtmlTruncator do
  let(:input) { '<p>Some short HTML content</p>' }

  describe 'truncate' do
    subject(:output) { described_class.new.truncate(input) }

    it 'does not change short (allowed) content' do
      expect(output).to eq '<p>Some short HTML content</p>'
    end

    context 'with disallowed tags' do
      let(:input) { '<div>Some short HTML content</div>' }

      it 'removes them even from short content' do
        expect(output).to eq 'Some short HTML content'
      end
    end

    context 'with a reduced list of allowed tags' do
      subject(:output) { described_class.new.truncate(input, tags: %w[em strong]) }

      it 'removes tags not on that list' do
        expect(output).to eq 'Some short HTML content'
      end
    end

    context 'with HTML content exceeding the maximum length' do
      subject(:output) { described_class.new.truncate(input, max_length: 30) }

      let(:input) { '<p>Some more HTML content that is too long</p>' }

      it 'truncates the content to the specified length (not including tags)' do
        expect(output.length).to eq 37
      end

      it 'adds a truncation tail (...)' do
        expect(output).to eq '<p>Some more HTML content that...</p>'
      end
    end

    context 'with formatted content' do
      let(:input) { "<p>Some content</p><p>Some more\ncontent</p>" }

      it 'keeps line breaks and paragraphs' do
        expect(output).to eq "<p>Some content</p><p>Some more\ncontent</p>"
      end
    end

    context 'with styled content' do
      let(:input) { 'Some <b>bold</b>, <i>italic</i>, <strong>strong</strong>, and <em>emphasized</em> text' }

      it 'drops tags for presentation and keeps semantically relevant tags' do
        expect(output).to eq 'Some bold, italic, <strong>strong</strong>, and <em>emphasized</em> text'
      end
    end

    context 'with inline style' do
      let(:input) { '<p style="color: red">Some short content</p>' }

      it 'drops the inline style' do
        expect(output).to eq '<p>Some short content</p>'
      end
    end

    context 'with images' do
      let(:input) { '<p>An image:</p><p><img src="" alt="Some image" /></p>' }

      it 'drops images' do
        expect(output).to eq '<p>An image:</p><p></p>'
      end
    end

    context 'with links' do
      let(:input) { '<p>A link:</p><p><a href="https//:example.com">Link text</a></p>' }

      it 'keeps the link text only' do
        expect(output).to eq '<p>A link:</p><p>Link text</p>'
      end
    end

    context 'with lists' do
      subject(:output) { described_class.new(strip_lists: true).truncate(input) }

      let(:input) do
        '<p>A list:</p>' \
          '<ol><li>First</li><li>Second</li></ol>' \
          '<ul><li>First</li><li>Second</li></ul>'
      end

      it 'converts lists to lines with line breaks' do
        expect(output).to eq \
          '<p>A list:</p>' \
          'First<br/>Second<br/>' \
          'First<br/>Second<br/>'
      end
    end

    context 'with invalid HTML content' do
      let(:input) { '<p>Some short HTML content' }

      it 'properly closes truncated HTML content' do
        expect(output).to eq '<p>Some short HTML content</p>'
      end
    end
  end
end
