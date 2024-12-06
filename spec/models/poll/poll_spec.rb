# frozen_string_literal: true

require 'spec_helper'

describe Poll::Poll, type: :model do
  describe '(validations)' do
    subject { build(:poll, :current) }

    it { is_expected.to accept_values_for(:question, 'Why?') }
    it { is_expected.not_to accept_values_for(:question, nil, '') }

    context 'start date after end date' do
      subject { described_class.new attrs }

      let(:attrs) do
        {
          start_at: 1.week.from_now,
          end_at: 1.day.from_now,
        }
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe '.upcoming_for_user' do
    subject(:first_poll) { described_class.upcoming_for_user(user_id).first }

    let(:user_id) { generate(:user_id) }

    context 'with past, current and future polls' do
      let!(:current1) { create(:poll, :current, start_at: 2.days.ago) }
      let!(:current2) { create(:poll, :current, start_at: 3.days.ago) }

      before do
        create(:poll, :past)
        create(:poll, :future)
      end

      it 'returns the oldest current poll' do
        expect(first_poll).to eq current2
      end

      context 'when the user has already responded to the oldest one' do
        before { create(:poll_response, poll: current2, user_id:) }

        it 'returns the second-oldest current poll' do
          expect(first_poll).to eq current1
        end
      end

      context 'when another user has responded to the oldest one' do
        before { create(:poll_response, poll: current2) }

        it 'returns the oldest current poll again' do
          expect(first_poll).to eq current2
        end
      end
    end
  end

  describe '.started' do
    subject(:polls) { described_class.started }

    let!(:past) { create(:poll, :past) }
    let!(:current) { create(:poll, :current) }

    before do
      create(:poll, :future)
    end

    it 'includes started polls only' do
      expect(polls).to match [
        an_object_having_attributes(id: past.id),
        an_object_having_attributes(id: current.id),
      ]
    end
  end

  describe '.current' do
    subject(:polls) { described_class.current }

    let!(:current) { create(:poll, :current) }

    before do
      create(:poll, :past)
      create(:poll, :future)
    end

    it 'includes current polls only' do
      expect(polls).to match [
        an_object_having_attributes(id: current.id),
      ]
    end
  end

  describe '.latest_first' do
    subject(:polls) { described_class.latest_first }

    let!(:current1) { create(:poll, :current, start_at: 2.days.ago) }
    let!(:current2) { create(:poll, :current, start_at: 1.day.ago) }
    let!(:future) { create(:poll, :future) }

    it 'sorts latest poll first' do
      expect(polls).to match [
        an_object_having_attributes(id: future.id),
        an_object_having_attributes(id: current2.id),
        an_object_having_attributes(id: current1.id),
      ]
    end
  end

  describe '#reveal_results?' do
    subject { poll.reveal_results? }

    context 'for a poll that has ended' do
      let(:poll) { create(:poll, :past) }

      it { is_expected.to be true }
    end

    context 'for a running poll with few participants' do
      let(:poll) { create(:poll, :current, response_count: 3) }

      it { is_expected.to be false }
    end

    context 'for a running poll with 20 or more participants' do
      let(:poll) { create(:poll, :current, response_count: 20) }

      it { is_expected.to be true }
    end
  end

  describe '#add_option' do
    subject(:added_option) { poll.add_option(attrs) }

    let(:poll) { create(:poll, :future) }

    before { poll }

    context 'without a text' do
      let(:attrs) { {position: 3} }

      it { is_expected.not_to be_valid }
    end

    context 'without a position' do
      let(:attrs) { {text: 'Hey new option'} }

      it { is_expected.to be_valid }

      it 'is assigned a position that is higher than that of all other options' do
        expect(added_option.position).to eq poll.options.maximum(:position)
      end
    end

    context 'with an unused position' do
      let(:attrs) { {text: 'new option', position: 0} }

      it { is_expected.to be_valid }

      it 'saves that position' do
        expect(added_option).to have_attributes text: 'new option', position: 0
      end
    end

    context 'with the position of another existing option' do
      let(:attrs) { {text: 'new option', position: first_position} }
      let(:first_position) { poll.options.minimum(:position) }

      it { is_expected.to be_valid }

      it 'is assigned that position' do
        expect(added_option).to have_attributes text: 'new option', position: first_position
      end

      it 'increments the positions of all other options' do
        o1, o2, o3 = poll.options

        expect { added_option }.to \
          change { o1.reload.position }.by(1).and \
            change { o2.reload.position }.by(1).and \
              change { o3.reload.position }.by(1)
      end
    end

    describe 'based on poll state' do
      let(:attrs) { {text: 'new option', position: 0} }

      context 'when poll is not yet open' do
        let(:poll) { create(:poll, :future) }

        it 'creates a new option' do
          expect { added_option }.to change(Poll::Option, :count).by(1)
        end
      end

      context 'when poll has started' do
        let(:poll) { create(:poll, :current) }

        it 'does not create a new option' do
          expect { added_option }.not_to change(Poll::Option, :count)
        end
      end

      context 'when poll has ended' do
        let(:poll) { create(:poll, :past) }

        it 'does not create a new option' do
          expect { added_option }.not_to change(Poll::Option, :count)
        end
      end
    end
  end
end
