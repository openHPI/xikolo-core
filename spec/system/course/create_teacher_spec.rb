# frozen_string_literal: true

require 'spec_helper'

describe 'Create a standalone teacher', type: :system do
  let(:admin) { create(:'account_service/user', :gdpr_admin) }

  before do
    sign_in(user: admin)
  end

  it 'allows a GDPR administrator to create a new standalone teacher' do
    # And I am on the teacher list
    visit teachers_path

    # When I create a new teacher
    click_on 'New teacher'

    # And I fill in a name
    fill_in 'Name', with: 'Example teacher name'

    # And I submit the teacher information
    fill_markdown_editor 'Bio (English)', with: 'Example blurb english'
    fill_markdown_editor 'Bio (German)', with: 'Example blurb deutsch'
    click_on 'Save information'

    expect(page).to have_text 'Teacher information has been successfully saved!'

    expect(page).to have_text 'Example teacher name'
    expect(page).to have_text 'Example blurb english'
    expect(page).to have_text 'Example blurb deutsch'
  end
end
