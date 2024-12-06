# frozen_string_literal: true

module Steps::PeerAssessmentItem
  Given 'a new peer assessment item has been created' do
    send :'Given a new peer assessment has been created'
    context.with :assessment do |assessment|
      context.assign :item, create_item(content_id: assessment['id'],
        title: 'Test Peer Assessment',
        content_type: 'peer_assessment',
        exercise_type: 'main')
    end

    Server[:peerassessment].api.rel(:peer_assessment).patch(
      {item_id: context.fetch(:item)['id']},
      {id: context.fetch(:assessment)['id']}
    ).value!
  end

  Given 'there is a fully configured peer assessment item' do
    send :'Given a full peer assessment has been created'

    context.with :assessment do |assessment|
      context.assign :item, create_item(content_id: assessment['id'],
        title: 'Test Peer Assessment',
        content_type: 'peer_assessment',
        exercise_type: 'main')
    end

    Server[:peerassessment].api.rel(:peer_assessment).patch(
      {item_id: context.fetch(:item)['id']},
      {id: context.fetch(:assessment)['id']}
    ).value!

    send :'Given the peer assessment has fully configured steps'
  end

  When 'I add a title to the peer assessment item' do
    fill_in 'Title', with: 'Test Peer Assessment'
  end

  When 'I choose to create a new assessment' do
    select 'Create new assessment', from: '*New / existing assessment'
  end

  When 'I create the assessment item' do
    click_on 'Create Item'
  end

  Then 'the page should have additional fields' do
    expect(page).to have_content 'Exercise type'
    expect(page).to have_content '*New / existing assessment'
  end
end

Gurke.config.include Steps::PeerAssessmentItem
