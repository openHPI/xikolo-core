# frozen_string_literal: true

module Resources
  class Preferences
    def initialize(user, properties)
      @user = user
      @properties = properties
    end

    def get_bool(key, default: false)
      val = get(key)
      val.nil? ? default : val == 'true'
    end

    def get_int(key, default = 0)
      Integer get(key, default)
    end

    def merge!(values)
      @user.rel(:preferences).put(
        properties: @properties.merge(values)
      ).value!
    end

    private

    def get(key, default = nil)
      if @properties
        @properties.fetch(key, default)
      else
        default
      end
    end
  end
end
