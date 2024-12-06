# frozen_string_literal: true

module Steps::Places
  Given 'I am on the assessment edit page' do
    visit "/peer_assessments/#{short_uuid(context.fetch(:assessment)['id'])}/edit"
  end

  When 'I go to the peer assessment landing page' do
    visit "/peer_assessments/#{short_uuid(context.fetch(:assessment)['id'])}"
  end

  Then 'I should be on the assessment edit page' do
    expect(page).to have_content "Peer Assessment Configuration for 'Test Peer Assessment'"
  end

  def submission_path
    pa_id = short_uuid(context.fetch(:assessment)['id'])
    step_id = short_uuid(context.fetch(:assignment_submission)['id'])
    "/peer_assessments/#{pa_id}/steps/#{step_id}/submission/new"
  end

  def training_path
    pa_id = short_uuid(context.fetch(:assessment)['id'])
    step_id = short_uuid(context.fetch(:training)['id'])
    "/peer_assessments/#{pa_id}/steps/#{step_id}"
  end

  def peer_grading_path
    pa_id = short_uuid(context.fetch(:assessment)['id'])
    step_id = short_uuid(context.fetch(:peer_grading)['id'])
    "/peer_assessments/#{pa_id}/steps/#{step_id}"
  end

  Given 'I am on the peer assessment submission page' do
    visit submission_path
  end

  Then 'I am redirected to the submission' do
    expect(page).to have_current_path submission_path
  end

  When 'I go to the peer assessment learn to grade index page' do
    visit training_path
  end

  When 'I go to the peer assessment learn to grade new sample page' do
    visit "#{training_path}/training/new"
  end

  When 'I go to the peer assessment evaluate your peers index page' do
    visit peer_grading_path
  end
end

Gurke.config.include Steps::Places
