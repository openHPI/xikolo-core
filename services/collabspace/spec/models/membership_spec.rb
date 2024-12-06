# frozen_string_literal: true

require 'spec_helper'

describe Membership, type: :model do
  let(:collab_space_attrs) { attributes_for(:collab_space) }
  let(:collab_space_id) { SecureRandom.uuid }
  let(:user_id) { '00000001-3100-4444-9999-000000000007' }
  let(:params) { {collab_space_id:, user_id:} }

  before { create(:collab_space, collab_space_attrs.merge(id: collab_space_id)) }

  describe 'validity' do
    subject(:membership) { described_class.new(params) }

    it 'is valid with both user_id and collab_space_id' do
      expect(membership).to be_valid
    end

    it 'does not allow duplication of user_id/collab_space_id combos' do
      described_class.create(params)
      expect(membership).not_to be_valid
    end

    # no spec like this for only invalid with a user_id
    # collab_space due to wanting to add memberships to
    # collab spaces that are not yet saved to the DB and therefore not have an id
    context 'without user_id' do
      let(:params) { super().except(:user_id) }

      it 'is invalid with just a collab_space_id' do
        expect(membership).not_to be_valid
      end
    end

    context 'when already member in another team in the same course' do
      let(:owner_id) { SecureRandom.uuid }
      let(:membership_params) { {user_id:} }
      let(:collab_space_attrs) { attributes_for(:team, :same_course) }

      before do
        create(:team, :same_course, owner_id:)
          .memberships.create(membership_params)
      end

      it { is_expected.not_to be_valid }

      context 'as mentor' do
        let(:membership_params) { super().merge! status: 'mentor' }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'status' do
    subject(:membership) { described_class.new(params.merge(additional_params)) }

    let(:additional_params) { {} }

    it 'has a regular status as default' do
      expect(membership.status).to eq 'regular'
    end

    context 'admin' do
      let(:additional_params) { {status: 'admin'} }

      it { is_expected.to be_valid }

      it 'has admin status' do
        expect(membership.status).to eq 'admin'
      end
    end

    context 'pending' do
      let(:additional_params) { {status: 'pending'} }

      it { is_expected.to be_valid }

      it 'is pending' do
        expect(membership.status).to eq 'pending'
      end
    end

    context 'mentor' do
      let(:additional_params) { {status: 'mentor'} }

      it { is_expected.to be_valid }

      it 'has mentor state' do
        expect(membership.status).to eq 'mentor'
      end
    end

    context 'with a weird status' do
      let(:additional_params) { {status: 'weird'} }

      it { is_expected.not_to be_valid }
    end
  end

  context '(event publication)' do
    subject(:new_membership) do
      build(:membership, collab_space:)
    end

    let!(:collab_space) { create(:collab_space) }

    it 'publishes an event for newly created membership' do
      # Let the membership factory also create the corresponding collab space
      new_membership

      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.collabspace.membership.create'))

      new_membership.save
    end

    it 'publishes an event for a destroyed membership' do
      new_membership.save

      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.collabspace.membership.destroy'))

      new_membership.destroy
    end
  end
end
