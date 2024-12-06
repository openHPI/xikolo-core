# frozen_string_literal: true

module Dashboard
  module Poll
    class Question < ApplicationComponent
      def self.vote(poll)
        new(poll, mode: :voting)
      end

      def self.results(poll, stats:, choices: [])
        new(poll, mode: :results, stats:, choices:)
      end

      private

      def initialize(poll, mode:, **opts)
        @poll = poll
        @mode = mode
        @choices = []

        if mode == :results
          @stats = opts.fetch(:stats)
          @choices = opts[:choices] || []
        end
      end

      def voting?
        @mode == :voting
      end

      def results?
        @mode == :results
      end

      def chosen?(option)
        @choices.include?(option.id)
      end

      def percentage(option)
        @percentages ||= Hash.new do |h, k|
          h[k] = if @stats.participants.zero?
                   0
                 else
                   (@stats.responses[k].to_f / @stats.participants * 100).round
                 end
        end

        @percentages[option]
      end
    end
  end
end
