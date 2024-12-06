# frozen_string_literal: true

require 'spec_helper'

describe Poll::Poll, '#stats' do
  subject(:stats) { poll.stats }

  let(:poll) { create(:poll, :current) }

  before do
    create(:poll_response, poll:, choices: [poll.options[0].id])
    create(:poll_response, poll:, choices: [poll.options[0].id])
    create(:poll_response, poll:, choices: [poll.options[1].id])
    create(:poll_response, poll:, choices: [poll.options[2].id])
  end

  it 'knows the number of participants' do
    expect(stats.participants).to eq 4
  end

  it 'aggregates the number of participants per answer' do
    expect(stats.responses).to eq(
      poll.options[0] => 2,
      poll.options[1] => 1,
      poll.options[2] => 1
    )
  end

  context 'for multiple-choice polls' do
    let(:poll) { create(:poll, :current, :multiple_choice) }

    before do
      create(:poll_response, poll:, choices: [poll.options[0].id, poll.options[1].id])
      create(:poll_response, poll:, choices: [poll.options[0].id, poll.options[2].id])
      create(:poll_response, poll:, choices: [poll.options[1].id, poll.options[2].id])
      create(:poll_response, poll:, choices: [poll.options[2].id, poll.options[0].id])
    end

    it 'still aggregates correctly' do
      expect(stats.responses).to eq(
        poll.options[0] => 5,
        poll.options[1] => 3,
        poll.options[2] => 4
      )
    end
  end
end
