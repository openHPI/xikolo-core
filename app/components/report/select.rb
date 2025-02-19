# frozen_string_literal: true

module Report
  class Select < ApplicationComponent
    def initialize(prefill_value:, opts:)
      @prefill_value = prefill_value
      @name = opts.fetch(:name)
      @label = opts.fetch(:label)
      @values = opts.fetch(:values)
      @options = opts.fetch(:options)
    end

    def with_form(form)
      @form = form
      self
    end

    private

    HTML_OPTIONS = %i[required].freeze
    private_constant :HTML_OPTIONS

    def html_options
      # Rails select tags have a distinct html_options block, that needs to be sent as its own argument.
      # https://github.com/rails/rails/blob/main/actionview/lib/action_view/helpers/tags/select.rb
      # https://stackoverflow.com/questions/16135954/rails-form-select-required/16140258#16140258
      @options.slice(*HTML_OPTIONS)
    end

    def options
      @options.except(*HTML_OPTIONS).merge(selected:)
    end

    def selected
      @prefill_value.presence || @options[:selected]
    end
  end
end
