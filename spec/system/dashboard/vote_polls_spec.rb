# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard: Vote on polls', type: :system do
  before do
    user = build(:'account:user')
    stub_user id: user['id'], permissions: %w[polls.archive]
    Stub.request(:account, :get, "/users/#{user['id']}")
      .and_return Stub.json(user)
    Stub.request(:account, :post, '/tokens')
      .to_return Stub.json({token: 'abc'})

    Stub.request(:course, :get, '/courses', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:course, :get, '/api/v2/course/courses', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:course, :get, '/enrollments', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    create(:poll, :past, :with_responses)

    create(:poll, :current, :multiple_choice,
      show_intermediate_results: false,
      start_at: 3.days.ago,
      question: 'Which of these platform features do you use regularly?',
      option_texts: ['Course list', 'Dashboard', 'Polls'])

    create(:poll, :current, :with_sufficient_response_count,
      start_at: 2.days.ago,
      question: 'Which poll did you like better?',
      option_texts: ['The previous one', 'This one', 'None of the above'])
  end

  it 'allows voting on current polls' do
    visit '/dashboard'

    expect(page).to have_content 'Which of these platform features do you use regularly?'

    find('label', text: 'Dashboard', visible: :all).click
    find('label', text: 'Polls', visible: :all).click
    click_on 'Vote'

    expect(page).to have_content 'Thank you for voting!'
    expect(page).to have_content 'You can see the results in the poll archive as soon as the poll ends.'

    click_on 'Next poll'

    expect(page).to have_content 'Which poll did you like better?'

    find('label', text: 'This one', visible: :all).click
    click_on 'Vote'

    expect(page).to have_content 'Thank you for voting!'
    expect(page).to have_content 'Intermediate results with 22 participants'

    expect(page).to have_no_link 'Next poll'
    click_on 'Recent poll results'

    # Poll 1 reveals neither statistics nor my own choices
    expect(page).to have_content(/This poll ends on .+\. The results will be shown afterwards./, count: 1)
    expect(page).to have_no_checked_field 'Dashboard', disabled: true, visible: :all
    expect(page).to have_no_checked_field 'Polls', disabled: true, visible: :all

    # Poll 2 reveals intermediate statistics and my choices
    expect(page).to have_content 'Intermediate results with 22 participants', count: 1
    expect(page).to have_checked_field 'This one', disabled: true, visible: :all
  end
end
