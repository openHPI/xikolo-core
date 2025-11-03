# frozen_string_literal: true

require 'spec_helper'

describe Admin::Statistics::AgeDistribution do
  it 'formats shares as percentages and merges optional course columns' do
    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, '/groups/all').to_return Stub.json({'stats_url' => '/account_service/groups/all/stats'})
    Stub.request(:account, :get, '/groups/all/stats', query: hash_including({}))
      .to_return Stub.json({'user' => {'age' => {'0' => 65, '25' => 10, '35' => 5}}})

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses/test-course').to_return Stub.json({'students_group_url' => '/courses/test-course/students_group'})
    Stub.request(:course, :get, '/courses/test-course/students_group').to_return Stub.json({'stats_url' => '/courses/test-course/students_group/stats'})
    Stub.request(:course, :get, '/courses/test-course/students_group/stats', query: hash_including({}))
      .to_return Stub.json({'user' => {'age' => {'0' => 12, '35' => 3}}})

    rows = described_class.call(course_id: 'test-course')

    group_20_29 = rows.find {|r| r['age_group'] == '20-29' }
    group_30_39 = rows.find {|r| r['age_group'] == '30-39' }

    expect(group_20_29).to include(
      'global_count' => 10,
      'global_share' => '12.5%'
    )

    expect(group_30_39).to include(
      'global_count' => 5,
      'global_share' => '6.25%',
      'course_count' => 3,
      'course_share' => '20.0%'
    )
  end
end
