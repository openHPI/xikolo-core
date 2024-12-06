# frozen_string_literal: true

require 'spec_helper'

describe Poll::Poll, '#vote!' do
  subject(:vote) { poll.vote! choices, user_id: }

  let(:user_id) { generate(:user_id) }
  let(:choices) { [poll.options.first.id] }

  context 'when poll is already closed' do
    let(:poll) { create(:poll, :past) }

    it 'fails' do
      expect { vote }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when poll has not yet started' do
    let(:poll) { create(:poll, :future) }

    it 'fails' do
      expect { vote }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when poll is open' do
    let(:poll) { create(:poll, :current) }

    it 'succeeds and returns a response' do
      expect(vote).to be_a Poll::Response
    end

    context 'when the user has responded to this poll before' do
      before do
        create(:poll_response, poll:, user_id:)
      end

      it 'fails' do
        expect { vote }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when not choosing any option' do
      let(:choices) { [] }

      it 'fails' do
        expect { vote }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when choosing multiple options' do
      let(:choices) { [poll.options.first.id, poll.options.second.id] }

      it 'fails' do
        expect { vote }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when choosing multiple options for a multiple-choice poll' do
      let(:poll) { create(:poll, :current, :multiple_choice) }
      let(:choices) { [poll.options.first.id, poll.options.second.id] }

      it 'succeeds and returns a response' do
        expect(vote).to be_a Poll::Response
      end
    end
  end
end
