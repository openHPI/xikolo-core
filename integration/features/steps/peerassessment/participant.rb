# frozen_string_literal: true

module Steps::Participant
  def create_participant(user_id)
    data = {
      user_id:,
      peer_assessment_id: context.fetch(:assessment)['id'],
    }
    Server[:peerassessment].api.rel(:participants).post(data).value!
  end

  def create_participants(users)
    participants = users.map do |user|
      create_participant(user['id'])
    end
    context.assign :participants, participants
  end

  def update_participant(participant_id, update_type)
    Server[:peerassessment].api.rel(:participant).patch(
      {update_type:},
      {id: participant_id}
    )
  end

  Given 'I started the assessment' do
    participant = create_participant context.fetch(:user)['id']
    context.assign :participant, participant

    update_participant context.fetch(:participant)['id'], 'advance'
  end

  Given 'I advanced to the next step' do
    update_participant context.fetch(:participant)['id'], 'advance'
  end

  Given 'there exist some participants' do
    # Create users
    send :'Given there exist some users'

    # Create participants
    users = context.fetch :users
    create_participants users

    # Let participants start the assessment
    participants = context.fetch :participants
    participants.each do |participant|
      update_participant participant['id'], 'advance'
    end
  end

  Given(/^I skipped the ([\w *]+) phase/) do |_|
    update_participant context.fetch(:participant)['id'], 'skip'
  end
end

Gurke.config.include Steps::Participant
