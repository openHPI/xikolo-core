# frozen_string_literal: true

require 'spec_helper'

describe 'Edit section properties', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user', :admin) }
  let!(:section) { create(:'course_service/section', course:) }

  before do
    sign_in(user: admin)
    visit "/learn/#{course.course_code}/sections"
  end

  it 'successfully edits the section settings' do
    # When I edit the sections settings
    click_on 'Action'
    click_on 'Edit'
    fill_in 'Title', with: 'Edited Title'
    fill_in 'Description', with: 'Edited Description'

    click_on 'Update Section'

    # Then the edited section should be listed
    expect(page).to have_text 'Edited Title'
    expect(page).to have_text 'Edited Description'

    # And I should get visual feedback that the action was successful
    expect(page).to have_text 'The section Edited Title has been updated.'
  end

  it 'successfully moves a section' do
    # When I add a section
    click_on 'Add section'

    # And I fill in the section information
    fill_in 'Title', with: 'Week 1'

    # And I save the section
    click_on 'Create Section'

    expect(page).to have_text('The section Week 1 has been updated.')

    expect(find('ul.sections > li:first-child')).to have_text(section.title)
    expect(find('ul.sections > li:last-child')).to have_text('Week 1')

    find('ul.sections > li:last-child').drag_to(find('ul.sections > li:first-child'))

    # Ensure the backend handled the request to change the order
    visit current_path

    expect(find('ul.sections > li:first-child')).to have_text('Week 1')
    expect(find('ul.sections > li:last-child')).to have_text(section.title)
  end
end
