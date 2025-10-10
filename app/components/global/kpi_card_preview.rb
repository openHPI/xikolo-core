# frozen_string_literal: true

module Global
  class KpiCardPreview < ViewComponent::Preview
    def default
      render Global::KpiCard.new(
        icon_class: 'graduation-cap',
        title: 'Enrollments',
        metrics: [
          {counter: '8', title: 'Total'},
          {counter: '+0', title: 'Last 24 hours'},
          {counter: '5', title: 'At middle', quota_text: '5 non-deleted', quota: '100%'},
          {counter: '7', title: 'At end', quota_text: '7 non-deleted', quota: '100%'},
        ]
      )
    end

    def empty_state
      render Global::KpiCard.new(
        icon_class: 'chart-line',
        title: 'Course Activity',
        metrics: [],
        empty_message: 'No activity yet'
      )
    end
  end
end
