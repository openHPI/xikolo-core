# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Reports: Index', type: :system do
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }
  let(:download_url) { 'http://myfile.com/123abc' }
  let(:course) { build(:'course:course', title: 'Ruby for Beginners', course_code: 'ruby2021') }

  before do
    stub_user id: user_id, permissions: %w[lanalytics.report.create]
    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses', query: {alphabetic: true, public: true, groups: 'any'})
      .and_return Stub.json([course])
    Stub.request(:course, :get, '/classifiers', query: {cluster: 'category,reporting,topic'})
      .and_return Stub.json([])

    Stub.service(:learnanalytics, build(:'lanalytics:root'))

    Stub.request(:learnanalytics, :get, '/report_types')
      .to_return Stub.json([
        build(:'lanalytics:report_type', :course_report),
        build(:'lanalytics:report_type', :enrollment_statistics_report),
        build(:'lanalytics:report_type', :submission_report),
      ])

    Stub.request(:learnanalytics, :get, '/report_jobs', query: {user_id:, per_page: 200})
      .and_return Stub.json([
        {
          id: '1c6d65c1-99e3-4e9e-a3cb-cfa78a85b0c1',
          task_type: 'course_report',
          task_scope: '00000001-3300-4444-9999-000000000001',
          status: 'done',
          job_params: nil,
          download_url:,
          file_expire_date: '2021-06-22T07:57:09.132Z',
          user_id:,
          options: {},
          progress: 100,
          annotation: 'cloud2013',
        },
        {
          id: '0106cf94-ad35-4d92-8d01-7e2c84dc1c6d',
          task_type: 'submission_report',
          task_scope: '123',
          status: 'failing',
          job_params: nil,
          download_url: nil,
          file_expire_date: nil,
          user_id:,
          options: {},
          progress: nil,
          annotation: nil,
          error_text: 'Something bad happened',
        },
      ])
  end

  it 'displays the report jobs table' do
    visit '/reports'

    assert_selector('tr', text: 'course_report cloud2013 done Will expire at: June 22, 2021 07:57')
    assert_selector("a[href='#{download_url}']", text: 'Download')
    assert_selector('tr', text: 'submission_report failing')
    assert_selector('button', text: 'Show error details')
    assert_selector('a', text: 'Delete', count: 2)
    assert_selector('a', text: 'Restart')
  end

  it 'expands and prefills the course report form based on query parameters' do
    visit "/reports?report_type=course_report&report_scope=#{course['id']}&include_profile=true"

    within '[data-controller="accordion"]' do
      # the correct panel is expanded
      expect(page).to have_content 'This report includes data about each enrollment of a course.'

      # select prefill
      expect(page).to have_select('Select a course:', selected: 'ruby2021 - Ruby for Beginners')

      # checkbox prefill
      expect(page).to have_field('Include additional profile data. Sensitive data is omitted if pseudonymized.', type: 'checkbox', checked: true)
    end
  end

  it 'expands and prefills the submission report form based on query parameters' do
    visit '/reports?report_type=submission_report&report_scope=123-456'

    within '[data-controller="accordion"]' do
      # the correct panel is expanded
      expect(page).to have_content 'This report includes data about each submission of a quiz.'

      # text field prefill
      expect(page).to have_field('Enter a Quiz ID (the Content ID of the item):', type: 'text', with: '123-456')
    end
  end

  it 'expands and prefills the enrollment statistics report form based on query parameters' do
    visit '/reports?report_type=enrollment_statistics_report&window_size=12&window_unit=months&first_date=2020-01-01'

    within '[data-controller="accordion"]' do
      # the correct panel is expanded
      expect(page).to have_content 'This report includes the total enrollments count and unique enrolled users count for a given timeframe.'

      # date field prefill
      expect(page).to have_field('First date:', type: 'date', with: '2020-01-01')

      # number field prefill
      expect(page).to have_field('Length of time window:', type: 'number', with: '12')

      # radio group prefill
      expect(page).to have_field('Months (the day input fields are ignored)', type: 'radio', checked: true)
    end
  end
end
