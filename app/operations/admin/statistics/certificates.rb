# frozen_string_literal: true

module Admin
  module Statistics
    class Certificates < ApplicationOperation
      include MetricHelpers

      def call
        certificates = fetch_metric(name: 'certificates').value!
        return {} if certificates.blank?

        {
          'roa_count' => certificates['record_of_achievement'],
          'cop_count' => certificates['confirmation_of_participation'],
        }
      end
    end
  end
end
