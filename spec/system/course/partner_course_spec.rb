# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Partner course only visible for partners', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    # Ensure the feature works as expected
    create(:'account_service/group', name: 'company.partner')
    create(:'account_service/feature', owner: admin, name: 'course.access-group', value: 'true')

    xi_config <<~YML
      access_groups:
        company.partner: Partners
    YML
  end

  context 'when creating a course with partner restriction' do
    it 'allows an admin to select the partner group restriction' do
      create(:'course_service/channel', public: true)

      sign_in(user: admin)
      visit new_course_path

      fill_in 'Title', with: 'Partner Course'
      fill_in 'Course code', with: 'partner1'
      select 'English', from: 'Content language'
      fill_markdown_editor 'Abstract', with: 'This is a partner course.'
      fill_markdown_editor 'Description', with: 'Here is the full description.'

      tom_select 'Partners', from: 'Restricted to groups'
      tom_select 'Channel EN', from: 'Channels', search: true

      fill_in 'Start date (UTC)', with: 2.days.ago.iso8601
      find('body').click
      fill_in 'End date (UTC)', with: 19.days.from_now.iso8601
      find('body').click

      page.execute_script("document.querySelector('form').noValidate = true;")
      find('.btn-group input[type="submit"]').click

      expect(page).to have_text 'Partner Course'

      visit edit_course_path('partner1')

      # Verify that "company.partner" is selected
      expect(find('select#course_groups', visible: :all).value).to include('company.partner')
    end
  end

  context 'with an existing partner course' do
    let(:user) { create(:'account_service/user') }
    let(:partner_course) do
      create(:'course_service/course', title: 'Partner Course', course_code: 'partner1', placement: ['Open4All'])
    end

    before do
      # Set groups via the API or model
      partner_course.update!(groups: ['company.partner'])
      create(:'account_service/feature', owner: user, name: 'course.access-group', value: 'true')
    end

    it 'is not visible for a normal user' do
      sign_in(user: user)
      click_on 'Learn'

      expect(page).to have_text 'Nothing here yet — check back soon!'
    end

    it 'is visible for a partner user and allows enrollment' do
      # Add user to partner group
      create(:'account_service/membership', user: user, group: AccountService::Group.find_by(name: 'company.partner'))

      sign_in(user: user)
      click_on 'Learn'

      expect(page).to have_text 'Partner Course'

      enroll_in(partner_course)

      expect(page).to have_text 'You have been enrolled successfully.'
    end
  end
end
