# frozen_string_literal: true

module Report
  class Form < ApplicationComponent
    def initialize(report)
      @report = report
    end

    private

    def scope
      return if @report.scope.blank?

      prefill_value = if @report.prefill? && @report.prefill_data&.key?(:report_scope)
                        @report.prefill_data[:report_scope]
                      end

      options = @report.scope.dup
      component_class = "Report::#{options.delete(:type).camelize}".constantize
      component_class.new(prefill_value:, opts: options)
    end

    def options
      return [] if @report.options.blank?

      @report.options.map do |component_options|
        prefill_value = if @report.prefill? && @report.prefill_data&.key?(component_options[:name])
                          @report.prefill_data[component_options[:name]]
                        end

        # e.g. Report::Checkbox.new(type: 'checkbox', name: :machine_headers, label: 'Better machine-readable headers.')
        options = component_options.dup
        component_class = "Report::#{options.delete(:type).camelize}".constantize
        component_class.new(prefill_value:, opts: options)
      end
    end
  end
end
