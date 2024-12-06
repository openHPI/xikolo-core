# frozen_string_literal: true

module Report
  class Checkbox < ApplicationComponent
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
      @options.merge(checked: checked?)
    end

    def checked?
      if @prefill_value.present?
        ActiveModel::Type::Boolean.new.cast(@prefill_value)
      else
        @options[:checked]
      end
    end
  end
end
