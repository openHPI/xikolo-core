# frozen_string_literal: true

module Util
  class DatepickerPreview < ViewComponent::Preview
    def default
      render_with_template(
        template: 'util/datepicker/datepicker'
      )
    end
  end
end
