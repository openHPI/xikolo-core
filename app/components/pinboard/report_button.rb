# frozen_string_literal: true

class Pinboard::ReportButton < ApplicationComponent
  # @param path [String] the URL to post the abuse report to
  # @param test_id [String] optional test identifier
  def initialize(path:, test_id: nil)
    @path         = path
    @test_id      = test_id
  end

  def call
    data_attributes = {
      confirm: I18n.t('pinboard.reporting.confirm'),
      tooltip: I18n.t('pinboard.reporting.tooltip'),
      'test-id': @test_id,
    }

    link_to @path,
      method: :post,
      class: 'report-button',
      data: data_attributes,
      aria: {label: I18n.t('pinboard.reporting.tooltip')} do
      safe_join([
        render(Global::FaIcon.new('flag', style: :solid, css_classes: 'report-button__icon')),
        tag.span(I18n.t('pinboard.reporting.report')),
      ])
    end
  end
end
