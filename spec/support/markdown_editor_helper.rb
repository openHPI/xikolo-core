# frozen_string_literal: true

module MarkdownEditorHelper
  # A helper for Capyabara tests that need to set or read values from a toastUI editor:
  # * fill_markdown_editor: equivalent to fill_in for toastUI editor
  # * have_markdown_editor: equivalent to have_field for toastUI editor
  #
  # @from (string): Label from markdown editor (unless use_selector is set to true)
  # @use_selector (boolean): Find input selector instead of label if set to true
  # @with (string): Text content from markdown editor

  def fill_markdown_editor(from, use_selector: false, with: '')
    locator = use_selector ? find(from.to_s, visible: false) : find(:label, text: from)
    container = locator.ancestor('.form-group')

    within(container) do
      input = find('[contenteditable="true"]')
      # Remove any text content before adding the new one
      input.execute_script("return arguments[0].innerHTML=''", input)
      input.send_keys(with)
    end
  end

  # rubocop:disable Naming/PredicateName
  def have_markdown_editor(from, use_selector: false, with: '')
    locator = use_selector ? find(from.to_s, visible: false) : find(:label, text: from)
    container = locator.ancestor('.form-group')

    within(container) do
      have_content(with)
    end
  end
  # rubocop:enable Naming/PredicateName
end

RSpec.configure do |config|
  config.include MarkdownEditorHelper
end
