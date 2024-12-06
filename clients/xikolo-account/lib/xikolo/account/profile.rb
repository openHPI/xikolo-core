# frozen_string_literal: true

module Xikolo::Account
  # == User Profile
  #
  # The user profile contains additional fields to customize the user. The
  # profile fields are configurable.
  #
  # The profile fields can be accessed by {#fields} that returns a associative
  # map of field names to {Field} objects.
  #
  # This objects allows to read name, title and values as well as update these
  # values. After changing one or multiple field values the changes can be
  # persisted by sending {#save!} to the profile resource.
  #
  # @example
  #   profile = Xikolo::Account::Profile.find user_id: user.id
  #   profile.fields[:profession].value #=> "None"
  #   profile.fields[:bio].value = "Hey. It's me. I'm great!"
  #   profile.save!
  #
  class Profile < Acfs::SingletonResource
    service Xikolo::Account::Client, path: '/users/:user_id/profile'

    attribute :user_id, :uuid

    # Return a associative map of all profile fields.
    #
    # @return [HashWithIndifferentAccess<String, Field>] A map of field names
    #   to {Field} objects.
    #
    # @see Field
    #
    def fields
      @fields ||= begin
        hash = ActiveSupport::HashWithIndifferentAccess.new
        attributes['fields'].each do |data|
          field            = Field.new data
          hash[field.name] = field
        end

        hash
      end
    end

    # A single profile field. It allows to access name and titles, the value
    # (or values) and provides methods to update the field value.
    #
    class Field
      attr_reader :data

      def initialize(data)
        @data = data
      end

      # Return field name.
      #
      # The name is a unique string to identify the field and is not localized.
      #
      def name
        data['name']
      end

      def title(lang = I18n.locale)
        data['title'][lang] ||
          data['title']['en'] ||
          data['title'].values.first
      end

      def available_values
        data['available_values']
      end

      def default_values
        data['default_values']
      end

      def default?
        values == default_values
      end

      def required?
        data['required']
      end

      def values
        data['values']
      end

      def values=(values)
        data['values'] = Array(values)
      end

      def value
        values.first
      end

      def type
        data['type']
      end

      def value=(value)
        self.values = [value.to_s]
      end
    end
  end
end
