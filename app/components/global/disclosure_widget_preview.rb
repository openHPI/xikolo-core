# frozen_string_literal: true

module Global
  class DisclosureWidgetPreview < ViewComponent::Preview
    include MarkdownHelper

    # @!group

    # Disclosure Widget
    # =================
    # Component from which the user can obtain additional content like information or controls.
    #
    # Summary labels
    # -----------------------
    # It is possible to configure two different labels:
    #
    # - `summary` (required) displayed when content is collapsed in its initial state
    # - `expanded_summary` (optional) displayed when user expanded the details
    #
    # Content
    # -------
    # Can be any HTML.
    #
    # Content language (optional)
    # ----------------
    # The `lang` attribute is important to indicate that content language is not necessarily
    # the same as platform language setting.
    #
    # Visibility (default: true)
    # ----------
    # The component can be present or not based on the `visible` parameter.
    # Try it out in the _params_ tab.

    def default
      render Global::DisclosureWidget.new(
        'Expand me!'
      ) do
        'Here is a simple text content.'
      end
    end

    def with_expanded_label
      render Global::DisclosureWidget.new(
        'Show details',
        expanded_summary: 'Hide details'
      ) do
        'Here is a simple text content.'
      end
    end

    # @param visible toggle
    def visibility(visible: true)
      render Global::DisclosureWidget.new(
        'Show explanation',
        visible:
      ) do
        'I will not be rendered base on a condition.'
      end
    end

    def with_markdown_content
      md_content = <<~CONTENT
        # Explanation

        Here is an explanation:

        * Yes
        * No

        | Syntax      | Description |
        | ----------- | ----------- |
        | Header      | Title       |
        | Paragraph   | Text        |
      CONTENT

      render Global::DisclosureWidget.new(
        'Markdown content',
        content_lang: 'en'
      ) do
        tag.div(render_markdown(md_content, allow_tables: true, escape_html: false), class: 'RenderedMarkdown',
          escape: false)
      end
    end

    # @!endgroup
  end
end
