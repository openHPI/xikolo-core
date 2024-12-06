# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Listing', type: :request do
  subject(:resource) { api.rel(:groups).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {} }
  let!(:groups) { create_list(:group, 5) }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with group resources' do
    expect(resource).to eq json(groups)
  end

  describe '?user' do
    let(:user) { create(:user) }
    let(:params) { {user: user.id} }

    before do
      user.groups << groups[1]
      user.groups << groups[2]

      other_user = create(:user)
      other_user.groups << groups[1]
      other_user.groups << groups[3]
      other_user.groups << groups[4]
    end

    it 'returns only groups the user has a membership' do
      expect(resource).to eq json(groups[1..2])
    end
  end

  describe '?tag' do
    let(:tagged_group) { groups.first }

    before { tagged_group.update!(tags: %w[access]) }

    context 'with a single tag to be filtered' do
      let(:params) { {tag: 'access'} }

      it 'returns only groups with the requested tags' do
        expect(resource).to eq json([tagged_group])
      end
    end
  end
end
