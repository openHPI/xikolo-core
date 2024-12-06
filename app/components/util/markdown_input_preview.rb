# frozen_string_literal: true

module Util
  class MarkdownInputPreview < ViewComponent::Preview
    # To transform form textarea elements into markdown editors add to them the attribute
    # data-behavior="markdown-form-input" and anoter div with data-behavior="markdown-editor".
    # Finally, wrap both elements with a div[data-behavior="markdown-editor-wrapper"] element.
    #
    # Since the textarea will delegate its focus state to the markdown editor, the browser will not be
    # able to add the build-in form validation message. If you want to keep it you can optionally add
    # the following paragraph element:
    # <p class='markdown-editor-error-message' id=textarea-id data-behavior='markdown-editor-error'></p>
    #
    # See the template for more details.
    #
    # @!group Without file upload
    def large
      render_with_template(
        template: 'util/markdown_input/markdown_input'
      )
    end

    # @!endgroup

    def with_file_upload
      render_with_template(template: 'util/markdown_input/markdown_input_with_upload')
    end
  end
end
