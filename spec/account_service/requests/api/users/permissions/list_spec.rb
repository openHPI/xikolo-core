# frozen_string_literal: true

require 'spec_helper'

describe 'List user permissions', type: :request do
  subject(:resource) { base.rel(:permissions).get.value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }

  let(:user) { create(:'account_service/user') }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  context '[permissions]' do
    subject { base.rel(:permissions).get({context: request_context}).value! }

    it_behaves_like 'shared:permissions'
  end
end
