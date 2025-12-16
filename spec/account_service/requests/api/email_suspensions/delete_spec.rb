# frozen_string_literal: true

require 'spec_helper'

describe 'EmailSuspensions: Destroy', type: :request do
  subject(:resource) { restify_email.rel(:suspension).delete.value! }

  let(:email) { create(:'account_service/email', address: 'p3k@example.de', primary: true) }
  let(:user)  { email.user }

  let(:api)           { restify_with_headers(account_service_url).get.value! }
  let(:restify_user)  { api.rel(:user).get({id: user}).value! }
  let(:restify_email) { restify_user.rel(:emails).get.value!.first }

  before do
    create(:'account_service/feature', owner: user, name: 'primary_email_suspended')
  end

  it 'responds with a status ok' do
    expect(resource).to respond_with :ok
  end

  it 'unsuspends the email address (removes the feature)' do
    expect { resource }.to change {
      AccountService::Feature.where(owner: user, name: 'primary_email_suspended').count
    }.from(1).to(0)
  end
end
