# frozen_string_literal: true

module Statistic
  extend ActiveSupport::Concern

  module ClassMethods
    def take
      queries = stats.map do |name, block|
        DSL.new(name).instance_eval(&block)
      end

      arel = Arel::SelectManager.new.project(queries)
      new(ActiveRecord::Base.connection.select_one(arel))
    end

    def stat_names
      stats.keys
    end

    def stat(name, &block)
      attr_accessor name

      stats[name.to_s] = block
    end

    private

    def stats
      @stats ||= {}
    end
  end

  class DSL
    attr_reader :name

    def initialize(name)
      @name = name.to_s.freeze
    end

    def count(relation)
      rel = relation.unscope(:order)

      Arel::SelectManager
        .new(rel.arel.as(Arel.sql('c')))
        .project(Arel.star.count.as(name))
    end
  end
end
