# frozen_string_literal: true

module Report
  class DateField < ApplicationComponent
    def initialize(prefill_value:, opts:)
      @prefill_value = prefill_value
      @name = opts.fetch(:name)
      @label = opts.fetch(:label)
      @options = opts.fetch(:options)
    end

    def with_form(form)
      @form = form
      self
    end

    private

    def options
      @options.merge(value:)
    end

    def value
      @prefill_value.presence || @options[:value]
    end
  end
end
