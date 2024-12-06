# frozen_string_literal: true

require 'spec_helper'

describe CollabSpace, type: :model do
  subject(:collab_space) { described_class.create params }

  let(:owner_id) { '00000001-3100-4444-9999-000000000001' }
  let(:no_member_id) { '00000001-3100-4444-9999-000000000077' }
  let(:name) { 'Test' }
  let(:is_open) { true }
  let(:course_id) { '00000001-3200-4444-9999-000000000003' }
  let(:params) { {name:, owner_id:, is_open:, course_id:} }

  describe '(attribute)' do
    it 'has the correct name' do
      expect(collab_space.name).to eq name
    end

    it 'has memberships' do
      expect(collab_space.memberships).not_to be_empty
    end

    it 'has the correct course_id' do
      expect(collab_space.course_id).to eq course_id
    end

    it 'is a group' do
      expect(collab_space.kind).to eq 'group'
    end

    context 'with kind' do
      let(:params) { super().merge(kind: 'team') }

      it 'is a group' do
        expect(collab_space.kind).to eq 'team'
      end
    end
  end

  it { is_expected.to be_open }
  it { is_expected.to be_valid }

  it 'has a valid factory' do
    expect(build(:collab_space)).to be_valid
  end

  it 'is not valid without a name' do
    expect(described_class.new(params.merge(name: nil))).not_to be_valid
  end

  describe 'only_teams scope' do
    subject(:teams) { described_class.only_teams }

    before do
      described_class.create! params
      described_class.create! params.merge(kind: 'team', is_open: false)
    end

    it 'only counts teams' do
      expect(teams.count).to eq 1
    end
  end

  describe 'open or not' do
    describe 'open not set' do
      let(:is_open) { nil }

      it { is_expected.not_to be_valid }
    end

    describe 'private' do
      let(:is_open) { false }

      it { is_expected.not_to be_open }
      it { is_expected.to be_private }
      it { is_expected.to be_valid }
    end

    describe 'open' do
      let(:is_open) { true }

      it { is_expected.to be_open }
      it { is_expected.not_to be_private }
      it { is_expected.to be_valid }
    end
  end

  describe 'as team' do
    subject(:team) { described_class.create params.merge(kind: 'team') }

    describe 'open' do
      it { is_expected.not_to be_valid }
    end

    describe 'private' do
      let(:is_open) { false }

      it { is_expected.to be_valid }
    end
  end

  describe 'memberships' do
    it 'initially has one member' do
      expect(collab_space.memberships.size).to eq 1
    end

    it 'has the owner as the only member' do
      expect(collab_space).to be_member owner_id
    end

    it 'has one member which is the admin' do
      expect(collab_space.memberships.first.status).to eq 'admin'
    end

    it 'does not have some semi random user as a member (yet)' do
      expect(collab_space).not_to be_member no_member_id
    end

    describe '#add_member' do
      let(:member_id) { '00000001-3100-4444-9999-000000000022' }

      before do
        collab_space.add_member member_id
      end

      it 'adds the user_id to the collection of memberships' do
        expect(collab_space).to be_member member_id
      end

      it 'does not add another member with the same id' do
        expect do
          collab_space.add_member member_id
        end.not_to change { Membership.all.size }
      end

      it 'deletes all members when the collab_space is destroyed' do
        collab_space_id = collab_space.id
        collab_space.destroy
        expect(Membership.where(collab_space_id:)).to be_empty
      end

      describe 'removing the member (#remove_member)' do
        it 'removes the member' do
          collab_space.remove_member member_id
          expect(collab_space).not_to be_member member_id
        end

        it 'returns a truthy value when removing succesfully' do
          expect(collab_space.remove_member(member_id)).to be_truthy
        end

        it 'returns a false value when not removing succesfully' do
          expect(collab_space.remove_member(no_member_id)).to be_falsey
        end
      end
    end

    context '(event publication)' do
      subject(:collab_space) { build(:collab_space) }

      it 'publishes an event for newly created collab space' do
        # The implementation throws a membership event before throwing the collab space event
        expect(Msgr).to receive(:publish).once
        expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.collabspace.collab_space.create'))
        collab_space.save
      end

      it 'publishes an event for updated collab space' do
        collab_space.save

        expect(Msgr).to receive(:publish) do |updated_collab_space_as_hash, msgr_params|
          expect(updated_collab_space_as_hash).to be_a(Hash)
          expect(updated_collab_space_as_hash).to include('name' => 'Really Awesome Collab Space')
          expect(msgr_params).to include(to: 'xikolo.collabspace.collab_space.update')
        end

        collab_space.name = 'Really Awesome Collab Space'
        collab_space.save
      end

      it 'publishes an event for a destroyed collab space' do
        collab_space.save

        # The implementation throws an event for the destroyed membership event before throwing destroy event for the collab space
        expect(Msgr).to receive(:publish).once
        expect(Msgr).to receive(:publish) do |destroyed_collab_space_as_hash, msgr_params|
          expect(destroyed_collab_space_as_hash).to be_a(Hash)
          expect(destroyed_collab_space_as_hash).to include('name' => collab_space.name)
          expect(msgr_params).to include(to: 'xikolo.collabspace.collab_space.destroy')
        end
        collab_space.destroy
      end
    end
  end
end
