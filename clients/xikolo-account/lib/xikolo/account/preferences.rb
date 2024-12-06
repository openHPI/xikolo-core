# frozen_string_literal: true

module Xikolo::Account
  class Preferences < Acfs::SingletonResource
    service Xikolo::Account::Client, path: '/users/:user_id/preferences'

    attribute :user_id, :string
    attribute :properties, :dict, default: {}

    # Get a specific user preference property.
    #
    # @example
    #   user.preferences.get 'social.social.allow_detection_via_name'
    #   => true
    def get(key, default = nil)
      if properties
        properties.fetch(key, default)
      else
        default
      end
    end
    alias [] get

    def get_bool(key, default: false)
      val = get(key)
      val.nil? ? default : val == 'true'
    end

    def get_int(key, default = 0)
      Integer get(key, default)
    end

    def set(key, value)
      if properties
        properties[key] = value
      else
        self.properties = {key => value}
      end
    end
    alias []= set

    def update(hash = {})
      self.properties = if properties
                          properties.merge(hash)
                        else
                          hash
                        end

      save!
    end
  end
end
