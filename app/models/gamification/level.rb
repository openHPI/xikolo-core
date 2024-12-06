# frozen_string_literal: true

module Gamification
  class Level
    class << self
      def all
        @all ||= YAML.load_file(File.expand_path('./user_levels.yml', __dir__)).map do |name, config|
          new(name, config)
        end
      end
    end

    attr_reader :name, :title, :image

    def initialize(name, config)
      @name = name
      @title = config['title']
      @min_xp = config['min_xp']
      @image = config['image']
    end

    # Compare levels (highest first)
    def <=>(other)
      other.min_xp <=> @min_xp
    end

    include Comparable

    def enough?(points)
      points >= min_xp
    end

    protected

    attr_reader :min_xp
  end
end
