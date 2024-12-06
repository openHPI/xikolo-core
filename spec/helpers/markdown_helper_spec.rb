# frozen_string_literal: true

require 'spec_helper'

describe MarkdownHelper, type: :helper do
  before do
    Xikolo.base_url = 'https://mydomain.de/'
  end

  describe '#render_markdown' do
    it 'renders absolute link' do
      expect(render_markdown("[][1]\r\n\r\n  [1]: https://mydomain.de")).to include('<a href="https://mydomain.de">https://mydomain.de</a>')
    end

    it 'renders relative link' do
      expect(render_markdown("[courses][1]\r\n\r\n  [1]: /courses")).to include('<a href="/courses">courses</a>')
    end

    it 'renders anchor link' do
      expect(render_markdown("[my anchor][1]\r\n\r\n  [1]: #my-anchor")).to include('<a href="#my-anchor">my anchor</a>')
    end

    it 'renders link with content' do
      expect(render_markdown("[link][1]\r\n\r\n  [1]: https://mydomain.de")).to include('<a href="https://mydomain.de">link</a>')
    end

    it 'renders link with title' do
      expect(render_markdown("[link][1]\r\n\r\n  [1]: https://mydomain.de \"mydomain\"")).to include('<a title="mydomain" href="https://mydomain.de">link</a>')
    end

    it 'renders external link with target blank' do
      expect(render_markdown("[link][1]\r\n\r\n  [1]: https://notmydomain.de")).to include('<a target="_blank" rel="noopener" href="https://notmydomain.de">link</a>')
    end

    it 'renders absolute files link with target blank' do
      expect(render_markdown("[link][1]\r\n\r\n  [1]: https://mydomain.de/files/123")).to include('<a target="_blank" rel="noopener" href="https://mydomain.de/files/123">link</a>')
    end

    it 'renders relative files link with target blank' do
      expect(render_markdown("[link][1]\r\n\r\n  [1]: /files/123")).to include('<a target="_blank" rel="noopener" href="/files/123">link</a>')
    end

    it 'renders mailto link' do
      expect(render_markdown("[mail][1]\r\n\r\n  [1]: mailto:admin@example.com")).to include('<a href="mailto:admin@example.com">mail</a>')
    end

    it 'strips links which it cannot understand' do
      expect(render_markdown("[mail][1]\r\n\r\n  [1]: mailto://admin@example.com")).to include('<a>mail</a>')
    end

    it 'renders backtick fenced code block' do
      expect(render_markdown(<<~MARKDOWN))
        ```
        code
        block
        ```
      MARKDOWN
        .to eq <<~TEXT
          <pre><code>code
          block
          </code></pre>
        TEXT
    end

    it 'escapes html' do
      expect(render_markdown("[<script>evil</script>][1]\r\n\r\n  [1]: https://mydomain.de")).to include('<a href="https://mydomain.de">&lt;script&gt;evil&lt;/script&gt;</a>')
    end

    it 'sanitizes javascript: href' do
      expect(render_markdown("[click here](javascript:alert('xss'))")).to include('<a>click here</a>')
    end
  end

  describe '#render_rich_text_item_markdown' do
    let(:item) { instance_double(RichTextItemPresenter, text_html: markdown, id: '6cb55cd8-dc58-476b-ab52-d625cbd6b5ad', course_id: 'b40245f4-de33-42c2-ac2c-916c8a61fa19') }

    context 'internal link' do
      let(:markdown) { "[link][1]\r\n\r\n  [1]: https://mydomain.de" }

      it 'renders internal link with tracking params' do
        expect(render_rich_text_item_markdown(item)).to include(
          '<a href="https://mydomain.de?' \
          'tracking_course_id=b40245f4-de33-42c2-ac2c-916c8a61fa19&' \
          'tracking_id=6cb55cd8-dc58-476b-ab52-d625cbd6b5ad&' \
          'tracking_type=rich_text_item_link&' \
          'url=https%3A%2F%2Fmydomain.de' \
          '">link</a>'
        )
      end
    end

    context 'email link' do
      let(:markdown) { "[email us!][1]\r\n\r\n  [1]: mailto:email@example.com" }

      it 'renders mail link without any tracking params' do
        expect(render_rich_text_item_markdown(item)).to include(
          '<a href="mailto:email@example.com">email us!</a>'
        )
      end
    end

    context 'external link' do
      let(:markdown) { "[link][1]\r\n\r\n  [1]: https://notmydomain.de" }

      it 'renders external link with tracking params' do
        expect(render_rich_text_item_markdown(item)).to include(
          '<a target="_blank" rel="noopener" ' \
          'href="https://mydomain.de/go/link?' \
          'url=https%3A%2F%2Fnotmydomain.de&checksum=c5e1b14&' \
          'tracking_type=rich_text_item_link&' \
          'tracking_id=6cb55cd8-dc58-476b-ab52-d625cbd6b5ad&' \
          'tracking_course_id=b40245f4-de33-42c2-ac2c-916c8a61fa19' \
          '">link</a>'
        )
      end
    end

    context 'relative file link' do
      let(:markdown) { "[link][1]\r\n\r\n  [1]: /files/123" }

      it 'is treated like an external link' do
        expect(render_rich_text_item_markdown(item)).to include(
          '<a target="_blank" rel="noopener" ' \
          'href="https://mydomain.de/go/link?' \
          'url=%2Ffiles%2F123&' \
          'checksum=48e9e01&' \
          'tracking_type=rich_text_item_link&' \
          'tracking_id=6cb55cd8-dc58-476b-ab52-d625cbd6b5ad&' \
          'tracking_course_id=b40245f4-de33-42c2-ac2c-916c8a61fa19' \
          '">link</a>'
        )
      end
    end

    context 'internal AND external links' do
      let(:markdown) do
        "[internal link][1] [external link][2]\r\n\r\n  [1]: https://mydomain.de/page42 \r\n [2]: http://notmydomain.de/route57"
      end

      it 'renders all links with correct tracking params' do
        expect(render_rich_text_item_markdown(item)).to include(
          '<a href="' \
          'https://mydomain.de/page42?' \
          'tracking_course_id=b40245f4-de33-42c2-ac2c-916c8a61fa19&' \
          'tracking_id=6cb55cd8-dc58-476b-ab52-d625cbd6b5ad&' \
          'tracking_type=rich_text_item_link&' \
          'url=https%3A%2F%2Fmydomain.de%2Fpage42' \
          '">internal link</a>'
        )

        expect(render_rich_text_item_markdown(item)).to include(
          '<a target="_blank" rel="noopener" ' \
          'href="https://mydomain.de/go/link?' \
          'url=http%3A%2F%2Fnotmydomain.de%2Froute57&' \
          'checksum=b82ec47&' \
          'tracking_type=rich_text_item_link&' \
          'tracking_id=6cb55cd8-dc58-476b-ab52-d625cbd6b5ad&' \
          'tracking_course_id=b40245f4-de33-42c2-ac2c-916c8a61fa19' \
          '">external link</a>'
        )
      end
    end

    context 'invalid link' do
      let(:markdown) { "[HEAT][1]\r\n\r\n  [1]: http://" }

      it 'is left as-is' do
        expect(render_rich_text_item_markdown(item)).to include(
          '<a href="http://">HEAT</a>'
        )
      end
    end
  end
end
