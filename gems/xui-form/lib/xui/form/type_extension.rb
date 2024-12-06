# frozen_string_literal: true

module XUI
  class Form
    #
    # Allow types to add validations and other model thinks by calling
    # callback method after definition
    #
    module TypeExtension
      def attribute(name, type, **opts)
        super
        type_cls = attribute_types[name.to_s]
        return unless type_cls.respond_to? :declared

        type_cls.declared(self, name, type)
      end
    end
  end
end
