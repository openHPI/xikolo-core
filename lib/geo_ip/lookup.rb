# frozen_string_literal: true

module GeoIP
  extend ActiveSupport::Autoload

  def self.eager_load!
    super
    Lookup.instance
  end

  class Lookup
    include Singleton

    attr_reader :db

    def initialize
      # Ensure that you have a fresh version of the MaxMind GeoLite2 Database
      # located in vendor/GeoLite2-Country. The database is NOT included
      # in the open source code base.
      # see https://dev.maxmind.com/geoip/geolite2-free-geolocation-data
      @db = MaxMindDB.new('vendor/GeoLite2-Country/GeoLite2-Country.mmdb')
    end

    def self.resolve(user_ip)
      instance.db.lookup(user_ip)
    end
  end
end
