# frozen_string_literal: true

module Steps::PeerAssessment
  def create_assessment(attrs = {})
    data = {
      title: 'Test Peer Assessment',
      course_id: context.fetch(:course)['id'],
    }
    data.merge! attrs
    data.compact!

    Server[:peerassessment].api.rel(:peer_assessments).post(data).value!
  end

  Given 'a new peer assessment has been created' do
    context.assign :assessment, create_assessment
  end

  Given 'a full peer assessment has been created' do
    context.assign :assessment, create_assessment(
      instructions: 'Some instructions for the test peer assessment',
      grading_hints: 'Some hints.',
      allowed_file_types: '.pdf, .png',
      allowed_attachments: 2
    )
  end

  When 'I fill in all information' do
    fill_markdown_editor '#markdown-input-instructions', use_selector: true, with: 'Some instructions'
    fill_markdown_editor '#markdown-input-grading_hints', use_selector: true, with: 'Some additional grading hints'
    fill_markdown_editor '#markdown-input-usage_disclaimer', use_selector: true, with: 'Please sell your soul to satan.'
    fill_in 'xikolo_peer_assessment_peer_assessment_allowed_attachments', with: 2
    fill_in 'xikolo_peer_assessment_peer_assessment_allowed_file_types', with: '.png, .pdf'
  end

  When 'I save the changes' do
    click_on 'Save Changes'
  end

  When(/^I click on the "([\w\s]+)" menu point/) do |menu|
    click_on menu
  end

  When 'I add a file to the dropzone' do
    drop_in_dropzone asset_path('mercedes.png')
    wait_for_ajax
  end

  When 'I choose all steps' do
    check 'Xikolo::PeerAssessment::Training'
    check 'Xikolo::PeerAssessment::SelfAssessment'
    click_on 'Create'
  end

  Then 'I should see the configuration page' do
    expect(page).to have_content 'Peer Assessment Configuration for'
    expect(page).to have_content 'General Assessment Configuration'
    expect(page).to have_content 'File Attachments'
    expect(page).to have_content 'Workflow Phases'
    expect(page).to have_content 'Grading Rubrics'
  end

  Then 'I see a success notification' do
    expect(page).to have_notice 'Your changes have been sucessfully saved'
  end

  Then 'all information are saved' do
    expect(page).to have_content 'Some instructions'
    expect(page).to have_content 'Some additional grading hints'
    expect(page).to have_content 'Please sell your soul to satan.'

    expect(page).to have_field('xikolo_peer_assessment_peer_assessment_allowed_attachments', with: 2)
    expect(page).to have_field('xikolo_peer_assessment_peer_assessment_allowed_file_types', with: '.png, .pdf')
  end

  Then 'I should see an uploaded file' do
    expect(page).to have_selector 'table tbody tr'
    expect(page).to have_content 'mercedes.png'
    expect(page).to have_link 'Download'
    expect(page).to have_button 'Delete File'
  end

  # Then 'I should be able to download it' do
  #  click_on 'Download'
  #  # Don't know how to properly test downloads. Does not seem to be easy with capybara.
  # end

  Then 'I should be able to delete it' do
    accept_alert do
      click_on 'Delete File'
    end

    wait_for_ajax
    expect(page).not_to have_selector 'table tbody tr'
  end
end

Gurke.config.include Steps::PeerAssessment
