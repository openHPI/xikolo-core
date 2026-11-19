# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Delete stream', type: :system do
  let(:admin) { create(:'account_service/user', :admin) }
  let(:stream) { create(:stream, title: 'the_course_intro_pip2') }

  before do
    stream
    sign_in(user: admin)
  end

  it 'deletes a stream' do
    visit '/videos'

    expect(page).to have_text 'the_course_intro_pip2'

    find('[aria-label="More actions"]').click
    within '[data-behaviour="menu-dropdown"]' do
      click_on 'Delete'
    end
    within '[role=dialog][aria-modal=true]' do
      click_on 'Yes, sure'
    end

    expect(page).to have_text 'The video stream has been deleted.'
    expect(page).to have_no_text 'the_course_intro_pip2'
  end
end
