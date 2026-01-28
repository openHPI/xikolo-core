# frozen_string_literal: true

require 'i18n'
require 'i18n/exceptions'

I18n.enforce_available_locales = true

module ActionView
  module Helpers
    module TranslationHelper
      alias orig_translate translate
      def translate(key, options = {})
        options[:rescue_format] = :html unless options.key?(:rescue_format)
        options[:default] = wrap_translate_defaults(options[:default]) if options[:default]

        html_safe_options = options.dup
        options.except(*I18n::RESERVED_KEYS).each do |name, value|
          unless name == :count && value.is_a?(Numeric)
            html_safe_options[name] = ERB::Util.html_escape(value.to_s)
          end
        end

        translation = I18n.translate!(scope_key_by_partial(key), **html_safe_options)
        translation.respond_to?(:html_safe) ? translation.html_safe : translation # rubocop:disable Rails/OutputSafety
      rescue I18n::MissingTranslationData => e
        raise e if options[:raise]

        missing_key = I18n.normalize_keys(e.locale, e.key, nil).join('.')

        Rails.logger.warn "* Translation missing: #{missing_key}"

        if Rails.env.production? && e.locale != 'en'
          translate(key, options.merge(locale: :en))
        else
          "[[#{missing_key}]]"
        end
      end
      alias t translate
    end
  end
end
