# frozen_string_literal: true

require 'spec_helper'

describe 'List user groups', type: :request do
  subject(:resource) { base.rel(:groups).get.value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }
  let(:user) { create(:user) }

  let(:groups) { create_list(:group, 2) }

  before do
    user.memberships.create! group: groups[1]
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with features' do
    expect(resource.pluck('name')).to eq [groups[1].name]
  end
end
