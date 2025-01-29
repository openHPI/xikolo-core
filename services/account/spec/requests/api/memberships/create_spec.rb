# frozen_string_literal: true

require 'spec_helper'

describe 'Memberships: Creation', type: :request do
  subject(:resource) { api.rel(:memberships).post(data).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:data) { {user: user.to_param, group: 'test.group'} }

  let(:user) { create(:user) }

  shared_examples 'membership creation' do
    it 'responds with a created resource' do
      expect(resource).to respond_with :created
    end

    it 'responds with a follow location to created membership' do
      expect(resource.follow).to eq membership_url(Membership.last)
    end

    it 'creates a database record' do
      expect { resource }.to change(Membership, :count).from(0).to(1)

      expect(Membership.last.group).to eq Group.find_by! name: data[:group]
      expect(Membership.last.user).to eq user
    end

    it 'responses with a membership resource' do
      expect(resource).to eq json(Membership.last)
    end
  end

  context 'without existing group' do
    let(:group) { Group.last! }

    it_behaves_like 'membership creation'

    context 'with invalid group name' do
      let(:data) { {**super(), group: 'abc'} }

      it 'responds with a validation error' do
        expect { resource }.to raise_error Restify::ClientError do |error|
          expect(error.status).to eq :unprocessable_content
          expect(error.errors).to eq 'group' => %w[invalid]
        end
      end
    end
  end

  context 'with existing group' do
    let(:group) { create(:group) }
    let(:data) { {user: user.to_param, group: group.to_param} }

    it_behaves_like 'membership creation'

    context 'with existing membership' do
      let!(:membership) do
        create(:membership, user:, group:)
      end

      it 'responds with CREATED' do
        expect(resource).to respond_with :created
      end

      it 'points to existing membership resource' do
        expect(resource.follow).to eq membership_url(membership)
      end

      it 'does not create a second membership' do
        expect { resource }.not_to change(Membership, :count).from(1)
      end

      it 'responses with a membership resource' do
        expect(resource.data).to eq json(membership)
      end
    end
  end

  context 'with missing user' do
    let(:data) { {group: 'abc.de'} }

    it 'responds with a validation error' do
      expect { resource }.to raise_error Restify::ClientError do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'user' => %w[required]
      end
    end
  end

  context 'with invalid user' do
    let(:data) { {user: 'abc-565', group: 'abc.de'} }

    it 'responds with a validation error' do
      expect { resource }.to raise_error Restify::ClientError do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'user' => %w[required]
      end
    end
  end
end
