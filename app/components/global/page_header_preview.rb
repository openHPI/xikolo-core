# frozen_string_literal: true

module Global
  class PageHeaderPreview < ViewComponent::Preview
    include ActionView::Helpers::UrlHelper

    # @!group
    def simple
      render Global::PageHeader.new('Quantencomputing Summer School')
    end

    def with_subtitle
      render Global::PageHeader.new('Quantencomputing Summer School', subtitle: 'Offered by openHPI Team')
    end

    def with_pill
      render Global::PageHeader.new('Quantencomputing Summer School', subtitle: 'Offered by openHPI Team') do |c|
        c.with_pill 'Active course', color: :note
      end
    end

    def slim
      render Global::PageHeader.new('Quantencomputing Summer School', type: :slim, subtitle: 'openHPI Team') do |c|
        c.with_pill 'Active course', size: :small, color: :note
      end
    end

    def with_additional_custom_content
      render Global::PageHeader.new('Quantencomputing Summer School', subtitle: 'Offered by openHPI Team') do |c|
        c.with_pill 'Active course', color: :note
        link_to 'Click here', '/', class: 'red block mt5'
      end
    end

    def slim_with_additional_custom_content
      render Global::PageHeader.new('Quantencomputing Summer School', type: :slim, subtitle: 'openHPI Team') do |c|
        c.with_pill 'Active course', size: :small, color: :note
        link_to 'Click here', '/', class: 'red block'
      end
    end
    # @!endgroup

    # @param title
    # @param subtitle
    # @param pill
    def with_params(title: 'Quantencomputing Summer School', subtitle: 'Offered by openHPI Team', pill: 'Active course')
      render Global::PageHeader.new(title, subtitle:) do |c|
        if pill.present?
          c.with_pill pill, color: :note
        end
      end
    end

    # @param title
    # @param subtitle
    # @param pill
    def slim_with_params(title: 'Quantencomputing Summer School', subtitle: 'Offered by openHPI Team', type: :slim,
                         pill: 'Active course')
      render Global::PageHeader.new(title, subtitle:, type:) do |c|
        if pill.present?
          c.with_pill pill, size: :small, color: :note
        end
      end
    end
  end
end
