# frozen_string_literal: true

module Steps::WorkflowSteps
  def create_step(attrs = {})
    Server[:peerassessment].api.rel(:steps).post(attrs).value!
  end

  def configure_step(selector:, unlock_date:, deadline:)
    fill_in "xikolo_peer_assessment_#{selector}_unlock_date", with: unlock_date
    fill_in "xikolo_peer_assessment_#{selector}_deadline", with: deadline
  end

  def fill_in_date(field, date)
    fill_in field, with: date

    # Make sure that any dropdowns from the date field are hidden after
    # filling the field, to prevent them from covering other fields.
    page.find('body').click
  end

  def update_step(step:, unlock_date: nil, deadline: nil, required_reviews: nil, optional: nil)
    data = {
      unlock_date:,
      deadline:,
      required_reviews:,
      optional:,
    }
    data.compact!

    Server[:peerassessment].api.rel(:step).patch(data, id: step['id']).value!
  end

  Given 'the peer assessment has new steps' do
    assessment_id = context.fetch(:assessment)['id']
    context.assign :assignment_submission, create_step(
      type: 'AssignmentSubmission',
      position: 0,
      peer_assessment_id: assessment_id
    )
    context.assign :training, create_step(
      type: 'Training',
      position: 1,
      peer_assessment_id: assessment_id
    )
    context.assign :peer_grading, create_step(
      type: 'PeerGrading',
      position: 2,
      peer_assessment_id: assessment_id
    )
    context.assign :self_assessment, create_step(
      type: 'SelfAssessment',
      position: 3,
      peer_assessment_id: assessment_id
    )
    context.assign :results, create_step(
      type: 'Results',
      position: 4,
      peer_assessment_id: assessment_id
    )
  end

  Given 'the peer assessment has fully configured steps' do
    # By default, the assessment is not yet started and training and self assessment are optional
    send 'Given the peer assessment has new steps'
    update_step(
      step: context.fetch(:assignment_submission),
      unlock_date: 5.minutes.from_now.iso8601,
      deadline: 10.minutes.from_now.iso8601
    )
    update_step(
      step: context.fetch(:training),
      unlock_date: 5.minutes.from_now.iso8601,
      deadline: 10.minutes.from_now.iso8601,
      required_reviews: 2,
      optional: true
    )
    update_step(
      step: context.fetch(:peer_grading),
      unlock_date: 10.minutes.from_now.iso8601,
      deadline: 15.minutes.from_now.iso8601,
      required_reviews: 3
    )
    update_step(
      step: context.fetch(:self_assessment),
      unlock_date: 15.minutes.from_now.iso8601,
      deadline: 20.minutes.from_now.iso8601,
      optional: true
    )
    update_step(
      step: context.fetch(:results),
      unlock_date: 20.minutes.from_now.iso8601,
      deadline: 25.minutes.from_now.iso8601
    )
  end

  Given(/^the "([\w\s]+)" step requires (\d+) reviews/) do |step, count|
    Server[:peerassessment].api.rel(:step).patch(
      id: context.fetch(step.underscore.to_sym)[:id],
      required_reviews: count
    ).value!
  end

  Given(/^the "([\w\s]+)" step is (\w+)/) do |step, modifier|
    s = context.fetch(step.underscore.to_sym)
    case modifier
      when 'open'
        update_step step: s, unlock_date: 5.minutes.ago.iso8601, deadline: 5.minutes.from_now.iso8601
      when 'locked'
        update_step step: s, unlock_date: 5.minutes.from_now.iso8601
      when 'closed'
        update_step step: s, deadline: 5.minutes.ago.iso8601
    end
  end

  Given 'the assessment has not yet started' do
    update_step(
      step: context.fetch(:assignment_submission),
      unlock_date: 1.hour.from_now.iso8601,
      deadline: 2.hours.from_now.iso8601
    )
  end

  Given 'the Training step is open for student reviews' do
    Server[:peerassessment].api.rel(:step).patch(
      {training_opened: true},
      {id: context.fetch(:training)['id']}
    )
  end

  When 'I configure all steps and save' do
    configure_step(
      selector: 'assignment_submission',
      unlock_date: 5.minutes.from_now.iso8601,
      deadline: 10.minutes.from_now.iso8601
    )
    configure_step(
      selector: 'training',
      unlock_date: 10.minutes.from_now.iso8601,
      deadline: 15.minutes.from_now.iso8601
    )
    configure_step(
      selector: 'peer_grading',
      unlock_date: 15.minutes.from_now.iso8601,
      deadline: 20.minutes.from_now.iso8601
    )
    configure_step(
      selector: 'self_assessment',
      unlock_date: 20.minutes.from_now.iso8601,
      deadline: 25.minutes.from_now.iso8601
    )
    configure_step(
      selector: 'results',
      unlock_date: 25.minutes.from_now.iso8601,
      deadline: 30.minutes.from_now.iso8601
    )
    click_on 'Update Steps'
  end

  Then 'I should see a confirmation modal' do
    expect(page).to have_content 'Create phases'
    expect(page).to have_content 'Cancel'

    sleep 0.5 # Give Sweetalert some time to initalize its event handlers :(
  end

  Then 'I should see all step configurations' do
    expect(page).to have_content 'Step 1.: Submit your work'
    expect(page).to have_content 'Step 2.: Learn to grade'
    expect(page).to have_content 'Step 3.: Evaluate your peers'
    expect(page).to have_content 'Step 4.: Evaluate yourself'
    expect(page).to have_content 'Step 5.: View your results'
  end

  Then 'I should see a success message' do
    expect(page).to have_notice 'The peer assessment phases were created successfully.'
  end

  Then 'there should be a success message' do
    expect(page).to have_notice 'Successfully updated the workflow'
  end

  Then 'the dates should be saved' do
    expect(page).to have_no_selector 'input[type=text][value=""]'
  end
end

Gurke.config.include Steps::WorkflowSteps
