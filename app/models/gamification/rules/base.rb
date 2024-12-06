# frozen_string_literal: true

module Gamification
  module Rules
    # Subclasses MUST implement the #name method
    class Base
      def initialize(payload)
        @payload = payload
      end

      def create_score!
        return unless payload_has_required_keys?

        Gamification::Score.create score
      end

      private

      def score
        {
          user_id: receiver,
          course_id:,
          rule: name,
          points:,
          data:,
          checksum:,
        }
      end

      def payload_has_required_keys?
        required_keys.all? {|key| @payload.key? key }
      end

      def required_keys
        []
      end

      def receiver
        @payload.fetch :user_id
      end

      def course_id
        @payload.fetch :course_id
      end

      def active?(rule_name = nil)
        !rule_config(rule_name).nil?
      end

      def points
        rule_config['value']
      end

      def config_param(key)
        rule_config['params'][key.to_s]
      end

      def rule_config(rule_name = nil)
        rule_name ||= name

        Xikolo.config.gamification_rules['xp'][rule_name.to_s]
      end
    end
  end
end
