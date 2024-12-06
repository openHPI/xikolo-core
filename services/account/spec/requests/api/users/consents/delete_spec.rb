# frozen_string_literal: true

require 'spec_helper'

describe 'Delete user consents', type: :request do
  subject(:resource) { base.rel(:self).delete.value! }

  let(:api) { Restify.new(:test).get.value! }

  let(:base) do
    api.rel(:user).get(id: user).value!.rel(:consents).get.value!.first
  end

  let!(:consent) { create(:consent) }
  let(:user) { consent.user }
  let(:treatment) { consent.treatment }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'removes consent record' do
    expect { resource }.to change { user.consents.reload.count }.from(1).to(0)
  end
end
