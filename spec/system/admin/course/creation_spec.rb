# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Course', type: :system do
  let(:teachers) { build_list(:'course:teacher', 2) }
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }

  before do
    stub_user id: user_id, permissions: %w[course.course.create course.course.show course.teacher.view]
    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/channels', query: {per_page: 250})
      .and_return(Stub.json(build_list(:'course:channel', 3)))
    Stub.request(:course, :get, '/teachers', query: hash_including({}))
      .and_return(Stub.json(teachers))
    Stub.request(:course, :get, "/teachers/#{teachers.first['id']}")
      .and_return(Stub.json(teachers.first))
  end

  it 'prefills the form on unprocessable course data' do
    visit '/courses/new'

    fill_in 'Course code', with: 'test2018'
    fill_in 'Title', with: 'Automated Testing (2018 Edition)'
    fill_markdown_editor 'Description', with: 'This is the Automated Testing (2018 Edition).'
    select 'English', from: 'Content language'
    select 'Active', from: 'Status'

    all(:button, 'Advanced settings').map(&:click)

    tom_select teachers.first['name'], from: 'Teachers'

    fill_in('Learning goals', with: 'rspec').send_keys(:return)
    fill_in('Learning goals', with: 'capybara').send_keys(:return)

    fill_in 'Policy URL (in English)', with: 'https://xikolo.de/test2018/policies.en.html'
    fill_in 'Policy URL (in German)', with: 'https://xikolo.de/test2018/policies.de.html'

    Stub.request(:course, :post, '/courses')
      .to_return Stub.json({
        'errors' => {'course_code' => ['upload_error', 'Custom Error message']},
      }, status: 422)
    click_on 'Create course'

    expect(page).to have_content 'The course was not created.'
    expect(page).to have_content 'Custom Error message'
    expect(page).to have_content 'Your file upload could not be stored.'

    expect(page).to have_field('Course code', with: 'test2018')
    expect(page).to have_field('Title', with: 'Automated Testing (2018 Edition)')

    # Stubs for the course details page (where we will be redirected)
    new_course_id = generate(:course_id)
    Stub.request(:course, :get, '/courses/test2018').to_return do
      # HACK: The code relies on the created course,
      # so let's simulate that here.
      create(:course, id: new_course_id, course_code: 'test2018')

      Stub.json({
        'id' => new_course_id,
        'course_code' => 'test2018',
        'title' => 'Automated Testing (2018 Edition)',
        'lang' => 'en',
        'status' => 'active',
        'learning_goals' => %w[rspec capybara],
        'teacher_ids' => [teachers.first['id']],
        'middle_of_course' => nil,
      })
    end
    Stub.request(:course, :get, "/enrollments?course_id=#{new_course_id}&user_id=#{user_id}")
      .to_return Stub.json([])
    Stub.request(:course, :get, '/sections', query: {course_id: new_course_id})
      .to_return(Stub.json([]))
    Stub.request(:course, :get, '/items', query: hash_including(course_id: new_course_id, featured: 'true'))
      .to_return(Stub.json([]))
    Stub.request(:course, :get, "/stats?course_id=#{new_course_id}&key=enrollments")
      .to_return Stub.json({})
    Stub.request(:course, :get, "/stats?course_id=#{new_course_id}&key=percentile_created_at_days")
      .to_return Stub.json({percentile_created_at_days: {}, quantile_count: 0})
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    attributes = nil
    create_course = Stub.request(:course, :post, '/courses').with do |request|
      attributes = JSON.parse request.body
      true
    end.to_return(status: 201)

    click_on 'Create course'

    expect(page).to have_content 'The course has been created.'

    expect(create_course).to have_been_requested.twice

    expect(attributes).to include(
      'course_code' => 'test2018',
      'title' => 'Automated Testing (2018 Edition)',
      'status' => 'active',
      'learning_goals' => %w[rspec capybara],
      'teacher_ids' => [teachers.first['id']],
      'middle_of_course' => nil
    )

    expect(attributes).not_to have_key('middle_of_course_is_auto')

    expect(attributes['policy_url']).to include(
      'en' => 'https://xikolo.de/test2018/policies.en.html',
      'de' => 'https://xikolo.de/test2018/policies.de.html'
    )
  end
end
