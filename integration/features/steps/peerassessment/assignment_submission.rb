# frozen_string_literal: true

module Steps::AssignmentSubmission
  When 'I fill in nothing and submit' do
    send :'When I submit the solution'
  end

  When 'I fill in the submission and submit' do
    send :'When I fill in the submission'
    send :'When I submit the solution'
  end

  When 'I fill in the submission' do
    fill_markdown_editor '#markdown-input-text-new-question', use_selector: true, with: 'some answer'
  end

  When 'I submit the solution' do
    click_on 'Submit Solution'
  end

  When 'I confirm the submission warning' do
    within_dialog do
      click_on 'Yes, sure'
    end
  end

  Then 'I should be in the first step' do
    pa_id = short_uuid context.fetch(:assessment)['id']
    step_id = short_uuid context.fetch(:assignment_submission)['id']
    expect(page).to have_current_path "/peer_assessments/#{pa_id}/steps/#{step_id}/submission/new"
  end

  Then 'I should see an error concerning the completeness of my submission' do
    expect(page).to have_notice 'Your submission is empty. Please provide content in the text box or upload a file.'
  end

  Then 'I should see a success note about my submission' do
    expect(page).to have_notice 'Successfully submitted your solution.'
  end

  def get_submission(user_id)
    # Given 'I started the assessment' will update the participant,
    # which somehow seems to asynchronously create a submission, which
    # will be needed here. Fetching the index page will always return,
    # even if only with an empty list, and not raise an error.
    #
    # Instead, we will raise an error if there is no first element
    # returned, and retry that until we find something or we reach a
    # timeout.
    Test.wait(expect: [RuntimeError]) do
      submission = Server[:peerassessment].api.rel(:submissions).get(
        peer_assessment_id: context.fetch(:assessment)['id'],
        user_id:
      ).value!.first

      unless submission
        raise "No submission for peer_assessment_id=#{context.fetch(:assessment)['id']} user_id=#{user_id}"
      end

      submission
    end
  end

  def submit_solution(submission_id, text)
    Server[:peerassessment].api.rel(:submission).patch(
      {submitted: true, peer_assessment_id: context.fetch(:assessment)['id'], text:, attachments: []},
      {id: submission_id}
    ).value!
  end

  Given 'I submitted a solution' do
    submission = get_submission context.fetch(:user)['id']
    context.assign :my_submission, submit_solution(submission['id'], 'My Answer')
  end

  Given 'there are some submitted solutions' do
    send :'Given there exist some participants'

    # Submit some assignment submissions
    users = context.fetch :users
    users.each do |user|
      submission = get_submission user['id']
      submit_solution submission['id'], 'My Answer'
    end

    # Let the participants advance to the training step
    participants = context.fetch :participants
    participants.each do |participant|
      update_participant participant['id'], 'advance'
    end
  end
end

Gurke.config.include Steps::AssignmentSubmission
