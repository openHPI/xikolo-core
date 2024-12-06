# frozen_string_literal: true

require 'spec_helper'
require 'digest'

describe Collabspace::CollabspacePresenter do
  let!(:collabspace_id) { SecureRandom.uuid }
  let!(:course_id) { SecureRandom.uuid }

  let(:open_group) do
    Stub.json({
      name: 'a name',
      id: collabspace_id,
      is_open: true,
      kind: 'group',
    })
  end

  let(:closed_group) do
    Stub.json({
      name: 'a name',
      id: collabspace_id,
      is_open: false,
      kind: 'group',
    })
  end

  let(:team) do
    Stub.json({
      name: 'a name',
      id: collabspace_id,
      is_open: false,
      kind: 'team',
    })
  end

  let(:user_memberships) { [] }

  let!(:course_response) do
    Stub.json({
      id: course_id,
      title: 'My course',
      status: 'active',
    })
  end

  let(:collabspace_response) { open_group }

  let!(:course) { JSON.parse course_response[:body] }
  let(:collabspace) { JSON.parse collabspace_response[:body] }

  before do
    Stub.service(
      :collabspace,
      system_info_url: '/system_info/{id}',
      memberships_url: '/memberships'
    )

    Stub.service(
      :course,
      items_url: '/items'
    )
    Stub.request(
      :course, :get, "/course/#{course_id}"
    ).to_return course_response

    Stub.request(
      :collabspace, :get, "/collab_space/#{collabspace_id}"
    ).to_return collabspace_response
  end

  describe '.create' do
    let(:collabspace_response) { open_group }

    it 'creates a collab space' do
      presenter = described_class.create(collabspace, course, user_memberships:)
      expect(presenter).not_to eql(nil)
    end
  end

  describe '#name' do
    context 'is team collab space' do
      let(:collabspace_response) { team }

      it 'has a prefix Team in the name' do
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.name).to eql('Team: a name')
      end
    end

    context 'is group collab space' do
      let(:collabspace_response) { closed_group }

      it 'has no prefix in the name' do
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.name).to eql('a name')
      end
    end
  end

  describe '#team?' do
    context 'is team collab space' do
      let(:collabspace_response) { team }

      it 'is a team collab space' do
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.team?).to be(true)
      end
    end

    context 'is group collab space' do
      let(:collabspace_response) { open_group }

      it 'is a group collab space' do
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.team?).to be(false)
      end
    end
  end

  describe '#can_quit?' do
    context 'last admin' do
      let(:user_id1) { SecureRandom.uuid }
      let(:collabspace_response) { open_group }

      it 'cannot quit the collab space' do
        user_memberships = []
        # TODO: restify
        user_memberships << {'id' => user_id1, 'learning_room_id' => collabspace_id, 'status' => 'admin'}
        current_user = Xikolo::Account::User.find(user_id1)
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.can_quit?(current_user)).to be(false)
      end
    end

    context 'there is still an other admin left' do
      let(:user_id1) { SecureRandom.uuid }
      let(:user_id2) { SecureRandom.uuid }
      let(:collabspace_response) { open_group }

      it 'can quit the collab space' do
        user_memberships = []
        # TODO: restify
        user_memberships << {'id' => user_id1, 'learning_room_id' => collabspace_id, 'status' => 'admin'}
        user_memberships << {'id' => user_id2, 'learning_room_id' => collabspace_id, 'status' => 'admin'}
        current_user = Xikolo::Account::User.find(user_id1)
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.can_quit?(current_user)).to be(true)
      end
    end
  end

  describe '#can_join?' do
    context 'team collab space' do
      let(:collabspace_response) { team }

      it 'is not allowed to join' do # teaching team decides to which team you go
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.can_join?).to be(false)
      end
    end

    context 'group collab space' do
      let(:collabspace_response) { open_group }

      it 'is allowed to join' do # teaching team decides to which team you go
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.can_join?).to be(true)
      end
    end
  end

  describe '#index_action_button' do
    context 'team collab space' do
      let(:collabspace_response) { team }

      it 'returns an empty hash' do
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.index_action_button).to eql({})
      end
    end

    context 'open group collab space' do
      let(:collabspace_response) { open_group }

      it 'returns a not empty hash' do
        presenter = described_class.create(collabspace, course, user_memberships:)
        expect(presenter.index_action_button).to have_key(:label)
      end
    end
  end
end
