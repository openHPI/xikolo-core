# frozen_string_literal: true

require 'spec_helper'

describe Form::PasswordField, type: :component do
  subject(:component) { described_class.new(form, :password, **options) }

  let(:form) { ActionView::Helpers::FormBuilder.new(:login, nil, vc_test_controller.view_context, {}) }
  let(:options) { {} }

  it 'renders a password input wired up to the toggle' do
    render_inline(component)

    expect(page).to have_css(
      '[data-controller="password-toggle"]' \
      '[data-password-toggle-show-label-value="Show password"]' \
      '[data-password-toggle-hide-label-value="Hide password"]'
    )
    expect(page).to have_css(
      'input[type="password"][name="login[password]"][data-password-toggle-target="input"]'
    )
    expect(page).to have_css('button[data-action="password-toggle#toggle"][aria-label="Show password"]')
    expect(page).to have_css('[data-password-toggle-target="icon"]', count: 2, visible: :all)
  end

  it 'applies the default input styling' do
    render_inline(component)

    expect(page).to have_field(class: %w[x-input rounded-2xl w-full pr-10])
  end

  context 'with additional field options' do
    let(:options) { {required: true, autocomplete: 'new-password', placeholder: 'Your password'} }

    it 'passes them on to the input' do
      render_inline(component)

      expect(page).to have_css(
        'input[required][autocomplete="new-password"][placeholder="Your password"]'
      )
    end
  end
end
