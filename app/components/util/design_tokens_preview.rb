# frozen_string_literal: true

module Util
  class DesignTokensPreview < ViewComponent::Preview
    # Tokens from app/assets/stylesheets/tailwind/input.css, rendered in the active theme.
    def default
      render_with_template(
        template: 'util/design_tokens_preview',
        locals: {
          palettes: {
            primary: %w[bg-primary-900 bg-primary-800 bg-primary-600 bg-primary-500 bg-primary-250 bg-primary-100
                        bg-primary-50],
            secondary: %w[bg-secondary-100 bg-secondary-75 bg-secondary-50 bg-secondary-25 bg-secondary-10],
            tertiary: %w[bg-tertiary-900 bg-tertiary-500 bg-tertiary-100 bg-tertiary-50],
            accent: %w[bg-accent-75 bg-accent-50 bg-accent-25 bg-accent-10],
            error: %w[bg-error-900 bg-error-800 bg-error-700 bg-error-600 bg-error-500 bg-error-250 bg-error-100
                      bg-error-50],
            information: %w[bg-information-900 bg-information-500 bg-information-100 bg-information-50],
            success: %w[bg-success-900 bg-success-700 bg-success-500 bg-success-100 bg-success-50],
            note: %w[bg-note-900 bg-note-500 bg-note-100],
            gray: %w[bg-gray-900 bg-gray-800 bg-gray-600 bg-gray-500 bg-gray-250 bg-gray-100 bg-gray-50],
          },
          semantic_colors: %w[
            bg-base-100 text-base-content bg-base-200 text-base-content bg-base-300 text-base-content
            bg-primary text-primary-content bg-secondary text-secondary-content bg-accent text-accent-content
            bg-neutral text-neutral-content bg-info text-info-content bg-error text-error-content
            bg-success text-success-content bg-warning text-warning-content
          ].each_slice(2).to_a,
        }
      )
    end
  end
end
