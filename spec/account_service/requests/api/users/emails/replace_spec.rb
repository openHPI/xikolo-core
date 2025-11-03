# frozen_string_literal: true

require 'spec_helper'

describe "Replace user's email addresses", type: :request do
  subject(:resource) { base.rel(:emails).put(emails).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }
  let(:emails) { [] }
  let(:user) { create(:'account_service/user') }
  let!(:old_email) { user.primary_email }
  let!(:secondary_email) { create(:'account_service/email', user:, address: 'secondary@email.com', confirmed: true) }

  context 'with a valid email address' do
    let(:emails) { [{address: 'new@email.com', primary: true, confirmed: true}] }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'replaces the user email address' do
      expect { resource }.to change { user.reload.emails.first.address }
        .from(old_email.address).to('new@email.com')
    end

    it 'deletes existing email records for the user' do
      expect { resource }.to change { AccountService::Email.exists?(id: [old_email, secondary_email]) }.from(true).to(false)
      expect(user.reload.emails.size).to eq 1
    end

    it 'responds with the newly created email record attributes' do
      expect(resource.first.to_h).to include(
        'user_id' => user.id,
        'address' => 'new@email.com',
        'primary' => true,
        'confirmed' => true
      )
    end
  end

  shared_examples_for 'an invalid email address replacement request' do
    it 'responds with :unprocessable_content, and does not delete the old email record' do
      expect { resource }.to raise_error(Restify::UnprocessableEntity) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(AccountService::Email.exists?(old_email.id)).to be(true)
      end
    end
  end

  describe 'with an invalid email address' do
    let(:emails) { [{address: 'invalid-email', primary: true, confirmed: true}] }

    it_behaves_like 'an invalid email address replacement request'
  end

  describe 'with a primary but unconfirmed email address' do
    let(:emails) { [{address: 'new@email.com', primary: true}] }

    it_behaves_like 'an invalid email address replacement request'
  end

  describe 'with a confirmed but not primary email address' do
    let(:emails) { [{address: 'new@email.com', confirmed: true}] }

    it_behaves_like 'an invalid email address replacement request'
  end
end
