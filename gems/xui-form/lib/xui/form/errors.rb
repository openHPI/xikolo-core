# frozen_string_literal: true

module XUI
  class Form
    #
    # Extracts the form parameters from a strong_parameters
    # object using the form name.
    #
    module Errors
      def remote_errors(errors)
        return unless errors

        errors.each_pair do |field, messages|
          field = field.to_sym

          unless self.class.attribute_types.key?(field.to_s)
            if (field != :base) && defined?(::Sentry)
              ::Sentry.capture_message "Don't know how to map error on field '#{field}'"
            end

            field = :base
          end

          messages.each do |message|
            if /\A[a-z_]+\z/.match?(message)
              self.errors.add field, message.to_sym
            else
              self.errors.add field, message
            end
          end
        end
      end
    end
  end
end
