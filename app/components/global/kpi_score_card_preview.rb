# frozen_string_literal: true

module Global
  class KpiScoreCardPreview < ViewComponent::Preview
    def with_link
      render Global::KpiScoreCard.new(
        title: 'Item Visits',
        value: '304',
        icon_class: 'eye',
        more_details_url: '/statistics/visits'
      )
    end

    def without_link
      render Global::KpiScoreCard.new(
        title: 'Videos Played by Users',
        value: '4',
        icon_class: 'video'
      )
    end
  end
end
