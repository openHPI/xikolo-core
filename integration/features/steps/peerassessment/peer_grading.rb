# frozen_string_literal: true

module Steps::PeerGrading
  def request_review
    Server[:peerassessment].api.rel(:reviews).get(
      as_peer_grading: true,
      peer_assessment_id: context.fetch(:assessment)['id'],
      user_id: context.fetch(:user)['id']
    ).value!.first
  end

  Given 'there are some submissions to review' do
    send :'Given there are some submitted solutions'

    # Let the participants advance to the peer grading step so that their submissions are included in the grading pool
    participants = context.fetch :participants
    participants.each do |participant|
      update_participant participant['id'], 'advance'
    end
  end

  Given 'I have reviewed enough submissions' do
    # WIP
    3.times do
      review = request_review
      submit_review(review)
    end
  end

  When 'I click on the "Review first peer" button' do
    click_on 'Review first peer'
  end

  When 'I enter some written feedback' do
    fill_markdown_editor '[name="xikolo_peer_assessment_review[text]"]', use_selector: true, with: 'Some feedback'
  end

  Then 'I should see the peer grading page' do
    expect(page).to have_content "#{context.fetch(:assessment)[:title]}: Evaluate your peers"
  end

  Then 'I should see a "Tell me more about the Evaluate Your Peers phase" panel' do
    expect(page).to have_css('.panel-title', text: 'Tell me more about the Evaluate Your Peers phase')
  end

  Then 'I should see an info box to find out how many submissions I have to review' do
    expect(page).to have_css('.callout', text: <<~TEXT.strip)
      You need to evaluate a minimum of 3 submissions if you want \
      your own submission to be evaluated and considered for points.
    TEXT
  end

  Then 'there should collapse an explanation about the process and the grading guidelines' do
    expect(page).to have_css('.panel-body .callout', text: 'Process')
    expect(page).to have_css('.panel-body .callout', text: 'Grading Guideline')
  end

  Then 'I should see a flash message telling me that no submissions are available for grading' do
    expect(page).to have_selector(
      '[role=status][aria-live=polite]',
      text: 'There are currently no submissions available that you could grade'
    )
  end

  Then(/I should see a student's answer/) do
    expect(page).to have_content 'Student Answer'
  end

  Then 'I should not be able to submit an empty peer review' do
    click_on('Submit')
    has_current_path?("#{peer_grading_path}/reviews/new")
  end

  Then 'I should see an info box about reporting submissions' do
    expect(page).to have_css('.callout', text: <<~TEXT.strip)
      If you report a submission, the course team will check your report. \
      Your grading will not be included in your peer’s overall grade and \
      your feedback will not be visible to your peer. Please note that you \
      will then need to evaluate another submission instead of the \
      reported submission.
    TEXT
  end

  Then 'I should see a submit peer review confirmation modal' do
    expect(page).to have_content('You can still revise this review if the peer evaluation phase has not closed')
    expect(page).to have_content('Submit this review?')
    expect(page).to have_button('Yes, sure')
    expect(page).to have_button('Cancel')
  end

  Then 'I should see a message of successful peer review submission' do
    expect(page).to have_notice 'Successfully submitted your review'
  end
end

Gurke.config.include Steps::PeerGrading
