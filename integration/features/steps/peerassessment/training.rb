# frozen_string_literal: true

module Steps::Training
  def request_review_as_ta
    Server[:peerassessment].api.rel(:reviews).get(
      as_train_sample: true,
      peer_assessment_id: context.fetch(:assessment)['id'],
      user_id: context.fetch(:admin)['id']
    ).value!.first
  end

  def request_review_as_student
    Server[:peerassessment].api.rel(:reviews).get(
      as_student_training: true,
      peer_assessment_id: context.fetch(:assessment)['id'],
      user_id: context.fetch(:user)['id']
    ).value!.first
  end

  def submit_review(review)
    # Group the options by rubric
    options_per_rubric = context.fetch(:rubric_options).group_by {|option| option[:rubric_id] }

    # Get the ids of the first options of each rubric
    first_options_ids = []
    options_per_rubric.each_value do |options_of_a_rubric|
      first_options_ids << options_of_a_rubric.first['id']
    end

    data = {
      text: 'Detailed grading hints',
      optionIDs: first_options_ids,
      submitted: true,
    }
    params = {id: review['id']}
    Server[:peerassessment].api.rel(:review).patch(data, params)
  end

  Given 'there are sample reviews' do
    5.times do
      sample_review = request_review_as_ta
      submit_review(sample_review)
    end
  end

  Given 'I have trained enough' do
    2.times do
      review = request_review_as_student
      submit_review(review)
    end
  end

  When 'I click on the next step' do
    within '.pa-flow' do
      page.find_button('Evaluate your peers').click
    end
  end

  When 'I request the first training sample' do
    click_on 'First Sample'
  end

  When 'I select some grading options' do
    context.fetch(:rubrics).each do |rubric|
      choose("group_#{rubric['id']}", match: :first)
    end
  end

  When 'I click on the continue to the peer evaluation button' do
    click_on('Continue to the peer evaluation')
  end

  When 'I click on the start to evaluation your peers phase button' do
    click_on('Start the Evaluate Your Peers phase')
  end

  Then 'I should see the training page' do
    expect(page).to have_content "#{context.fetch(:assessment)[:title]}: Learn to grade"
  end

  Then 'I should see an info box about the unlock time' do
    expect(page).to have_css('.callout', text: 'This step is currently locked and will unlock in')
  end

  Then 'I should see an info box to find out why the training has not started yet' do
    expect(page).to have_css('.callout', text: <<~TEXT.strip)
      The instructors are currently grading submissions to provide a \
      grading reference. Once they are available you can complete the \
      training reviews.
    TEXT
  end

  Then 'there should collapse an explanation' do
    expect(page).to have_css('.panel-body .callout', text: 'The goal of the Learn to grade phase')
  end

  Then 'there should collapse some hints' do
    expect(page).to have_css('.panel-body', text: 'Some hints')
  end

  Then 'there should collapse the assignment instructions' do
    expect(page).to have_css('.panel-body', text: 'Some instructions for the test peer assessment')
  end

  Then 'I should see a confirmation modal to start the peer grading phase' do
    expect(page).to have_content <<~TEXT.strip
      Have you practiced enough? Do you really want to start the Evaluate Your Peers phase now?
    TEXT
    expect(page).to have_content <<~TEXT.strip
      Use the training samples to learn how to grade. Once you start the Evaluate Your Peers \
      phase, you can no longer view and grade the training samples.
    TEXT
    expect(page).to have_button('Start the Evaluate Your Peers phase')
    expect(page).to have_button('Go back to training samples')
  end

  Then 'I should see a button to request the first training sample' do
    expect(page).to have_link('First Sample')
  end

  Then 'I should see a training sample' do
    expect(page).to have_content('Student Answer')
    expect(page).to have_content('Your Grading')
  end

  Then 'I should not be able to submit an empty training review' do
    click_on('Submit')
    has_current_path?("#{training_path}/training/new")
  end

  Then 'I should see a submit training review confirmation modal' do
    expect(page).to have_content('Confirm submission')
    expect(page).to have_content('Submit this training review?')
    expect(page).to have_button('Yes, sure')
    expect(page).to have_button('Cancel')
  end

  Then 'I should see a message of successful training review submission' do
    expect(page).to have_notice 'Successfully submitted your review'
  end

  Then 'there should be an additional sample button' do
    expect(page).to have_link('Additional Sample')
  end
end

Gurke.config.include Steps::Training
