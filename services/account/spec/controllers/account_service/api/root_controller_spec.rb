# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::RootController, type: :request do
  subject(:resource) { Restify.new(account_service_url).get.value! }

  describe 'relations' do
    # Access internal relation map to tests for full match not only inclusion
    subject(:relations) { resource._restify_relations }

    it 'includes all expected relations' do
      expect(relations.keys).to match_array %w[
        authorization
        authorizations
        context
        contexts
        email
        email_suspensions
        grant
        grants
        group
        groups
        membership
        memberships
        password_reset
        password_resets
        policies
        role
        roles
        session
        sessions
        statistics
        system_info
        token
        tokens
        treatment
        treatments
        user
        user_ban
        users
      ]
    end
  end

  context 'rel(authorization)' do
    subject { super().rel(:authorization).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(authorizations)' do
    subject { super().rel(:authorizations).template.variables }

    it { is_expected.to eq %w[provider uid user] }
  end

  context 'rel(context)' do
    subject { super().rel(:context).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(contexts)' do
    subject { super().rel(:contexts).template.variables }

    it { is_expected.to eq %w[ancestors ascent] }
  end

  context 'rel(email)' do
    subject { super().rel(:email).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(email_suspensions)' do
    subject { super().rel(:email_suspensions).template.variables }

    it { is_expected.to eq %w[address] }
  end

  context 'rel(grants)' do
    subject { super().rel(:grants).template.variables }

    it { is_expected.to eq %w[role context] }
  end

  context 'rel(group)' do
    subject { super().rel(:group).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(groups)' do
    subject { super().rel(:groups).template.variables }

    it { is_expected.to match_array %w[user tag prefix] }
  end

  context 'rel(membership)' do
    subject { super().rel(:membership).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(memberships)' do
    subject { super().rel(:memberships).template.variables }

    it { is_expected.to eq %w[] }
  end

  context 'rel(passowrd_reset)' do
    subject { super().rel(:password_reset).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(policies)' do
    subject { super().rel(:policies).template.variables }

    it { is_expected.to eq %w[] }
  end

  context 'rel(role)' do
    subject { super().rel(:role).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(roles)' do
    subject { super().rel(:roles).template.variables }

    it { is_expected.to eq %w[] }
  end

  context 'rel(session)' do
    subject { super().rel(:session).template.variables }

    it { is_expected.to eq %w[id embed context] }
  end

  context 'rel(sessions)' do
    subject { super().rel(:sessions).template.variables }

    it { is_expected.to eq %w[] }
  end

  context 'rel(statistics)' do
    subject { super().rel(:statistics).template.variables }

    it { is_expected.to eq %w[] }
  end

  context 'rel(system_info)' do
    subject { super().rel(:system_info).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(token)' do
    subject { super().rel(:token).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(tokens)' do
    subject { super().rel(:tokens).template.variables }

    it { is_expected.to eq %w[token] }
  end

  context 'rel(treatment)' do
    subject { super().rel(:treatment).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(treatments)' do
    subject { super().rel(:treatments).template.variables }

    it { is_expected.to eq %w[] }
  end

  context 'rel(user)' do
    subject { super().rel(:user).template.variables }

    it { is_expected.to eq %w[id] }
  end

  context 'rel(users)' do
    subject { super().rel(:users).template.variables }

    it { is_expected.to eq %w[search query archived confirmed id permission context auth_uid] }
  end

  describe 'response' do
    describe 'Cache-Control' do
      subject(:cache_control) do
        resource.response.headers['CACHE_CONTROL'].strip.split(/\s*,\s*/)
      end

      it 'is public cacheable for 5 minutes' do
        expect(cache_control).to match_array %w[public max-age=300]
      end
    end

    describe 'Vary' do
      subject { resource.response.headers['VARY'].split(/\s*[,\n]\s*/) }

      it { is_expected.to match_array %w[Accept Host] }
    end
  end
end
