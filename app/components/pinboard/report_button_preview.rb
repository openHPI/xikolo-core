# frozen_string_literal: true

class Pinboard::ReportButtonPreview < ViewComponent::Preview
  def default
    render Pinboard::ReportButton.new(
      path: '/reports/demo',
      test_id: 'report-default'
    )
  end
end
