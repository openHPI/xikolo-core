# frozen_string_literal: true

module Global
  class KpiScoreCardPreview < ViewComponent::Preview
    # @param title text
    # @param value text
    # @param format select { choices: [count, percentage] }
    # @param icon_class text
    # @param more_details_url text
    def default(title: 'Quiz Performance', value: '0.75', format: :percentage, icon_class: 'user-edit',
                more_details_url: nil)
      format_sym = format.to_sym
      converted_value = format_sym == :percentage ? value.to_f : value.to_i

      render Global::KpiScoreCard.new(
        title:,
        value: converted_value,
        icon_class:,
        format: format_sym,
        more_details_url: more_details_url.presence
      )
    end
  end
end
