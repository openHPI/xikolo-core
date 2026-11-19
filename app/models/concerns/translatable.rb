# frozen_string_literal: true

module Translatable
  extend ActiveSupport::Concern

  class_methods do
    def translated_field(field, required: false)
      define_singleton_method("localized_#{field}_fields") do
        I18n.available_locales.map do |locale|
          "#{field}_#{locale}"
        end
      end

      define_method(field) do
        Translations.new(send("#{field}_translations")).to_s
      end

      I18n.available_locales.map(&:to_s).each do |locale|
        define_method("#{field}_#{locale}") do
          return if send("#{field}_translations").nil?

          send("#{field}_translations")[locale]
        end

        define_method("#{field}_#{locale}=") do |text|
          send("#{field}_translations=", {}) if send("#{field}_translations").nil?
          send("#{field}_translations")[locale] = text
        end

        # Validation options:
        # - required: true  -> validate presence for every locale (existing behaviour)
        # - required: :any  -> validate that at least one locale is present
        case required
          when true
            validates "#{field}_#{locale}", presence: true
          when :any
            validates "#{field}_#{locale}", presence: true, if: lambda {
              self.class.send("localized_#{field}_fields").none? { send(it).present? }
            }
        end
      end
    end
  end
end
