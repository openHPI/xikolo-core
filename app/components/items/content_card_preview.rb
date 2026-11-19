# frozen_string_literal: true

module Items
  class ContentCardPreview < ViewComponent::Preview
    include MarkdownHelper

    def rich_text
      render ContentCard.new(
        rendered_content: render_markdown(
          <<~MARKDOWN,
            ## Important information

            This is a rich-text item with **formatted text**, _emphasis_, and a [helpful link](https://open.hpi.de/).

            > A short quotation can call attention to an important point.

            ### What you will need

            - A modern web browser
            - About 30 minutes
            - Curiosity

            ```ruby
            course.enroll(user)
            ```

            | Topic | Duration | Material |
            | :---- | -------: | :------- |
            | Introduction | 10 min | Video |
            | Exercise | 20 min | Quiz |
          MARKDOWN
          allow_tables: true,
          escape_html: false
        ),
        lang: 'en'
      )
    end

    def with_title
      render ContentCard.new(
        rendered_content: render_markdown('This is a description with **formatted text**.', allow_tables: true),
        lang: 'en',
        title: 'There is a title for this content card'
      )
    end
  end
end
