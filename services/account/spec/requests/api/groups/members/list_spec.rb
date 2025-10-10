# frozen_string_literal: true

require 'spec_helper'

describe 'Groups Members: Listing', type: :request do
  subject(:resource) { base.rel(:members).get(params).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:base) { api.rel(:group).get({id: group}).value! }

  let(:params) { {} }
  let(:group) { create(:'account_service/group', name: 'owner.groupname') }
  let(:users) { create_list(:'account_service/user', 10) }

  # Overwritten in specific contexts
  # rubocop:disable RSpec/LetSetup
  let!(:setup) do
    group.members << users[1..3]
    group.members << users[5..7]
    group.members << users[9..9]
  end
  # rubocop:enable RSpec/LetSetup

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with user records' do
    expect(resource).to match_array json(users[1..3] + users[5..7] + users[9..9])
  end

  context 'with archived user' do
    let(:users) do
      [
        create(:'account_service/user'),
        create(:'account_service/user', :archived),
        *create_list(:'account_service/user', 10),
      ]
    end

    it 'does not return archived user' do
      expect(resource).to match_array json(users[2..3] + users[5..7] + users[9..9])
    end
  end

  context 'with unconfirmed user' do
    before { users[1].update! confirmed: false }

    it 'does not return unconfirmed user' do
      expect(resource).to match_array json(users[2..3] + users[5..7] + users[9..9])
    end
  end

  describe 'special groups' do
    let!(:users) do
      [
        User.anonymous,
        create(:'account_service/user'),
        create(:'account_service/user', :unconfirmed),
        create(:'account_service/user', archived: true),
        create(:'account_service/user'),
        create(:'account_service/user', :unconfirmed),
        create(:'account_service/user', :unconfirmed, archived: true),
      ]
    end

    context 'all' do
      let(:group) { Group.all_users }
      let(:setup) { nil }

      it { is_expected.to respond_with :ok }

      it 'contains all users' do
        expect(resource.size).to eq users.size
        expect(resource.map { it['id'] }).to match_array users.pluck(:id)
      end
    end

    context 'active' do
      let(:group) { Group.active_users }
      let(:setup) { nil }

      it { is_expected.to respond_with :ok }

      it 'contains only active users' do
        expect(resource.size).to eq 2
        expect(resource.map { it['id'] }).to match_array \
          [users[1], users[4]].pluck(:id)
      end
    end

    context 'confirmed' do
      let(:group) { Group.confirmed_users }
      let(:setup) { nil }

      it { is_expected.to respond_with :ok }

      it 'contains only confirmed users' do
        expect(resource.size).to eq 3
        expect(resource.map { it['id'] }).to match_array \
          [users[1], users[3], users[4]].pluck(:id)
      end
    end

    context 'unconfirmed' do
      let(:group) { Group.unconfirmed_users }
      let(:setup) { nil }

      it { is_expected.to respond_with :ok }

      it 'contains only unconfirmed users' do
        expect(resource.size).to eq 4
        expect(resource.map { it['id'] }).to match_array \
          [users[0], users[2], users[5], users[6]].pluck(:id)
      end
    end

    context 'archived' do
      let(:group) { Group.archived_users }
      let(:setup) { nil }

      before do
        expect(users[3]).to be_archived
        expect(users[6]).to be_archived
      end

      it { is_expected.to respond_with :ok }

      it 'contains only archived users' do
        expect(resource.size).to eq 2
        expect(resource.map { it['id'] }).to match_array \
          [users[3], users[6]].pluck(:id)
      end
    end
  end

  describe '<pagination>' do
    let(:members) { group.members }

    it 'includes initial pagination header' do
      expect(resource.response.headers).to include 'X_TOTAL_COUNT' => '7'
      expect(resource.response.headers).to include 'X_TOTAL_PAGES' => '1'
    end

    it 'defaults to 1000 items per page' do
      expect(resource.response.headers['X_PER_PAGE']).to eq '1000'
    end

    context 'with higher per page count' do
      let(:params) { {per_page: 1_000_000_000} }

      it 'limits to 2500 items per page' do
        expect(resource.response.headers['X_PER_PAGE']).to eq '2500'
      end
    end

    context do
      let(:params) { {per_page: 3} }

      it 'paginates group members' do
        res = resource

        expect(res.size).to eq 3
        expect(res.as_json.map { it['id'] }).to eq members[0, 3].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'

        res = res.rel(:next).get.value!

        expect(res.size).to eq 3
        expect(res.as_json.map { it['id'] }).to eq members[3, 3].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'

        res = res.rel(:next).get.value!

        expect(res.size).to eq 1
        expect(res.as_json.map { it['id'] }).to eq members[6, 1].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'
      end

      context 'with record UUID as page' do
        let(:params) { {per_page: 3, page: members[2].id} }

        it 'paginates group members' do
          res = resource

          expect(res.size).to eq 3
          expect(res.as_json.map { it['id'] }).to eq members[3, 3].map(&:id)

          expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'

          res = res.rel(:next).get.value!

          expect(res.size).to eq 1
          expect(res.as_json.map { it['id'] }).to eq members[6, 1].map(&:id)

          expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'
        end
      end

      context 'with page numbers' do
        let(:params) { {per_page: 3, page: 1} }

        it 'paginates group members' do
          res = resource

          expect(res.size).to eq 3
          expect(res.as_json.map { it['id'] }).to eq members[0, 3].map(&:id)
          expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'

          res = base.rel(:members).get({**params, page: 2}).value!

          expect(res.size).to eq 3
          expect(res.as_json.map { it['id'] }).to eq members[3, 3].map(&:id)
          expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'

          res = base.rel(:members).get({**params, page: 3}).value!

          expect(res.size).to eq 1
          expect(res.as_json.map { it['id'] }).to eq members[6, 1].map(&:id)
          expect(res.response.headers['X_TOTAL_COUNT']).to eq '7'
        end
      end
    end
  end
end
