# frozen_string_literal: true

module Global
  class CustomHeadSnippets < ApplicationComponent
    def render?
      active_snippets.any?
    end

    private

    def snippets
      active_snippets.pluck('html')
    end

    def active_snippets
      @active_snippets ||= Xikolo.config.custom_html.select do |snippet|
        Requirements[snippet].fulfilled?(helpers)
      end
    end

    class Requirements
      def self.[](snippet)
        return new([]) unless snippet['requirements']&.any?

        new(
          snippet['requirements'].map {|req| resolve(req) }
        )
      end

      def self.resolve(requirement)
        type = requirement.fetch('type')

        case type
          when 'cookie_consent'
            CookieConsent.new(requirement.fetch('name'))
          else
            raise "Not sure how to handle requirement of type #{type}"
        end
      rescue KeyError => e
        raise "Missing required key '#{e.key}' for requirement configuration"
      end

      def initialize(checks)
        @checks = checks
      end

      def fulfilled?(helpers)
        @checks.all? {|check| check.fulfilled?(helpers) }
      end

      class CookieConsent
        def initialize(name)
          @name = name
        end

        def fulfilled?(helpers)
          ConsentCookie.new(helpers.cookies).accepted?(@name)
        end
      end
    end
  end
end
