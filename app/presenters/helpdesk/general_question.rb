# frozen_string_literal: true

module Helpdesk
  class GeneralQuestion
    def initialize(opts = {})
      @opts = opts
    end

    def key
      @opts.fetch(:key)
    end

    def text
      locales = @opts.fetch(:text)
      locales.is_a?(Hash) ? Translations.new(locales) : I18n.t(locales)
    end

    def applicable?(user)
      return true unless @opts[:if]

      @opts[:if].call user
    end

    def as_option
      [text, @opts[:key]]
    end
  end
end
