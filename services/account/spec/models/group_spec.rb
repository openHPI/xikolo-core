# frozen_string_literal: true

require 'spec_helper'

describe Group, type: :model do
  subject(:group) { create(:group, name: 'with.game') }

  describe 'validations' do
    describe '#allowed_tags' do
      it { expect(group).to accept_values_for(:tags, [], %w[access custom_recipients]) }
      it { expect(group).not_to accept_values_for(:tags, %w[foo], %w[foo bar]) }
    end
  end

  describe '.prefix' do
    context 'when the query matches available groups' do
      it 'returns matching group' do
        expect(Group.prefix('wit')).to include(group)
      end
    end

    context "when the query doesn't match available groups" do
      it 'returns nothing' do
        expect(Group.prefix('witho')).not_to include(group)
      end
    end

    context "when the query doesn't match at the beginning of the group name" do
      it 'returns nothing' do
        expect(Group.prefix('game')).not_to include(group)
      end
    end
  end

  describe '.ensure!' do
    context 'with concurrent creations' do
      it 'creates one group only' do
        # NOTE: This spec is testing concurrent race condition behavior,
        # which inherently will not always fail or fail with the same
        # error. Therefore, actually failing code changes might not be
        # discovered in rare cases.

        threads = Array.new(5) do
          SafeThread.new do
            Group.transaction do
              expect(Group.affiliated_users).to be_a Group

              # Ensure SQL connection is still active and valid, and was
              # not aborted by failures in #ensure!.
              expect(
                ActiveRecord::Base.connection.exec_query('SELECT 1').rows
              ).to eq [[1]]
            end
          end
        end

        expect { threads.map(&:join!) }.not_to raise_error

        expect(Group.all.compact).to eq [Group.affiliated_users]
      end
    end
  end
end
