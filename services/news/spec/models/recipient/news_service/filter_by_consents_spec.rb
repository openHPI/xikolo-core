# frozen_string_literal: true

require 'spec_helper'

describe NewsService::FilterByConsents, type: :model do
  subject(:filtered) { described_class.new recipient, consents }

  let(:consents) { [] }
  let(:message) { create(:'news_service/message', consents:) }

  describe 'for user' do
    let(:recipient) { NewsService::Recipient::User.new 'the_id' }
    let(:user_groups) { [] }

    before do
      Stub.service(:account, build(:'account:root'))
      Stub.request(:account, :get, '/users/the_id')
        .to_return Stub.json({
          id: 'the_id',
          groups_url: '/account_service/users/the_id/groups',
        })
      Stub.request(:account, :get, '/users/the_id/groups')
        .to_return Stub.json(user_groups)
    end

    it 'without consents yields once' do
      expect {|b| filtered.each(&b) }.to yield_control.once
    end

    context 'with consent filter' do
      let(:consents) { %w[treatment.consent1 treatment.consent2] }

      context 'and the user consented to all treatments' do
        let(:user_groups) { [{name: 'treatment.consent1'}, {name: 'treatment.consent2'}] }

        it 'yields once' do
          expect {|b| filtered.each(&b) }.to yield_successive_args(
            hash_including('id' => 'the_id')
          )
        end
      end

      context 'and the user did not consent to all treatments' do
        let(:user_groups) { [{name: 'treatment.consent1'}] }

        it 'does not yield' do
          expect {|b| filtered.each(&b) }.not_to yield_control
        end
      end
    end
  end

  describe 'for group' do
    let(:recipient) { NewsService::Recipient::Group.new 'the.id', message }

    before do
      Stub.service(:account, build(:'account:root'))
      Stub.request(:account, :get, '/groups/the.id')
        .to_return Stub.json({members_url: '/account_service/groups/the.id/members'})

      Stub.request(:account, :get, '/groups/the.id/members')
        .to_return Stub.json(
          [{id: 1}, {id: 2}],
          headers: {
            'Link' => '</account_service/groups/the.id/members?page=2>; rel="next"',
          }
        )
      Stub.request(:account, :get, '/groups/the.id/members?page=2')
        .to_return Stub.json([{id: 3}, {id: 4}])
    end

    it 'without consents yields for all members' do
      expect {|b| filtered.each(&b) }.to yield_control.exactly(4).times
    end

    context 'with consent filter' do
      let(:consents) { %w[treatment.consent1 treatment.consent2] }

      context 'and not all users consented to all required treatments' do
        before do
          Stub.request(:account, :get, '/groups/treatment.consent1')
            .to_return Stub.json({memberships_url: '/account_service/groups/treatment.consent2/memberships'})
          Stub.request(:account, :get, '/groups/treatment.consent2')
            .to_return Stub.json({memberships_url: '/account_service/groups/treatment.consent2/memberships'})
          Stub.request(
            :account, :get, '/groups/treatment.consent1/memberships',
            query: {per_page: 10_000}
          ).to_return Stub.json([{user: 1}, {user: 2}, {user: 4}])
          Stub.request(
            :account, :get, '/groups/treatment.consent2/memberships',
            query: {per_page: 10_000}
          ).to_return Stub.json([{user: 1}, {user: 4}])
        end

        it 'yields for all members but two' do
          expect {|b| filtered.each(&b) }.to yield_successive_args(
            hash_including('id' => 1),
            hash_including('id' => 4)
          )
        end
      end
    end
  end
end
