# frozen_string_literal: true

require 'active_support/concern'

module XUI
  class Form
    #
    # Support defining an attribute for a set of keys, e.g. all available locales
    # In the processed output, the values will be arranged as directory.
    #
    # Usage:
    #
    #   class Form
    #     hash_attribute :description, :text, keys: %w[en de]
    #     # or
    #     localized_attribute :description, :text
    #   end
    #
    #   f = Form.new 'text' => {'en' => 'English', 'de' => 'Deutsch'}
    #   f.text_en # => 'English'
    #   f.text_de # => 'Deutsch'
    #   f.to_resource # => {'text' => {'en' => 'English', 'de' => 'Deutsch'}}
    #
    # The locales parameter allows to configure the list of allowed locales.
    # Xikolo.config.locales['available'] is used per default.
    # The option of hash_attributes is named "keys" and is required!
    #
    # Keys can be configured as static list or as a proc that generates a new
    # list for every form instance:
    #
    #   hash_attribute :consents, :boolean,
    #     keys: proc {|form| form.all_available_consents }
    #
    # This module also adds a fallback to generate a human attribute name
    # e.g. used by SimpleForm for label fields.
    # It executes a lookup for the field name without suffix (like description)
    # and adds '(in $lang)'.
    #
    module HashFields
      extend ActiveSupport::Concern

      class_methods do
        def human_attribute_name(name, options = {})
          # fallback handling of localized fields like `description_en`
          # or `description_de`
          if name =~ /^(.+)_([a-zA-Z-]{2,})$/ && Xikolo.config.locales['available'].include?(Regexp.last_match(2))
            catch :exception do
              base = I18n.t :"simple_form.labels.#{model_name.singular}.#{Regexp.last_match(1)}",
                throw: true
              locale = I18n.t :"languages.title.#{Regexp.last_match(2)}", throw: true
              return I18n.t :'simple_form.in_language', field: base, lang: locale,
                throw: true
            end
          end

          super
        end

        def hash_attribute(name, type, keys:, subtype_opts: {}, **)
          subtype = ActiveModel::Type.lookup(type, **subtype_opts)
          attribute(name, :hash, subtype:, keys:, **)
        end

        def localized_attribute(name, type, **kwargs)
          keys = kwargs.delete(:locales) { Xikolo.config.locales['available'] }
          hash_attribute name, type, keys:, **kwargs
        end
      end
    end
  end
end
