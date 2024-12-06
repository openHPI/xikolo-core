# frozen_string_literal: true

class Admin::ReportPresenter
  attr_reader :prefill_data

  def initialize(report, courses, classifiers, prefill_data = nil)
    @report = report
    @courses = courses
    @classifiers = classifiers
    @prefill_data = prefill_data
  end

  def type
    @report['type']
  end

  def name
    @report['name']
  end

  def description
    @report['description']
  end

  def scope
    return unless @report.key?('scope')

    formatted_options(@report['scope'])
  end

  def options
    @report['options'].map {|option| formatted_options(option) }
  end

  def prefill?
    @prefill_data&.dig(:report_type) == type
  end

  private

  def formatted_options(attributes)
    options = attributes.to_h.transform_keys(&:to_sym)
    options[:options] = parsed_options(attributes['options'])

    if attributes['type'] == 'select'
      # This infers the proper select tag.
      options[:values] = case attributes['values']
                           when 'courses'
                             @courses
                           when 'classifiers'
                             @classifiers
                         end
    end

    options
  end

  def parsed_options(attributes)
    attributes.to_h do |key, value|
      if key == 'input_size'
        [:class, "report__input--#{value}"]
      else
        [key.to_sym, value]
      end
    end
  end
end
