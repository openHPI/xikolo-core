# frozen_string_literal: true

module Report
  class RadioGroup < ApplicationComponent
    def initialize(prefill_value:, opts:)
      @prefill_value = prefill_value
      @name = opts.fetch(:name)
      @label = opts.fetch(:label)
      @values = opts.fetch(:values)
    end

    def with_form(form)
      @form = form
      self
    end

    private

    def values
      @values.map.with_index do |(value_name, value_label), index|
        [
          value_name,
          value_label,
          {checked: (!valid_prefill_value? && index.zero?) || @prefill_value == value_name},
        ]
      end
    end

    def valid_prefill_value?
      @values.key? @prefill_value
    end
  end
end
