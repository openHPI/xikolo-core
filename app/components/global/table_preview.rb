# frozen_string_literal: true

module Global
  class TablePreview < ViewComponent::Preview
    def default
      data = [
        {'age_group' => '18–24', 'global_count' => '1,234', 'global_share' => '12%'},
        {'age_group' => '25–34', 'global_count' => '2,345', 'global_share' => '23%'},
        {'age_group' => '35–44', 'global_count' => '1,890', 'global_share' => '19%'},
        {'age_group' => '45–54', 'global_count' => '1,234', 'global_share' => '12%'},
      ]
      headers = ['Age Group', 'Global Count', 'Global Share']

      render Global::Table.new(data: data, headers: headers, title: 'Age Distribution')
    end

    def empty_data
      render Global::Table.new(data: [], headers: [], title: 'Empty Data Example')
    end
  end
end
