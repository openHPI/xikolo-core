# frozen_string_literal: true

require 'spec_helper'

describe CurrentUser::Base, type: :model do
  subject(:base_user) do
    Class.new(described_class) do
      attr_reader :user

      def initialize(user:, context_id:)
        @user = user
        super(context_id:)
      end
    end.new(context_id:, user:)
  end

  let(:context_id) { 'root' }
  let(:user) do
    instance_double(AccountService::User,
      id: 123, language: 'de', primary_email: nil, preferences: {'abc' => true})
  end

  describe '#id' do
    it 'returns the users id' do
      expect(base_user.id).to eq(123)
    end
  end

  describe '#preferred_language' do
    it 'returns the users language as perferred_languare' do
      expect(base_user.preferred_language).to eq('de')
    end
  end

  describe '#email' do
    context 'when the user has an email' do
      let(:user) { create(:'account_service/user') }

      it 'returns the users email' do
        expect(base_user.email).to eq(user.primary_email.address)
      end
    end

    context 'when the user has no email' do
      it 'returns nothing if the user has no email' do
        expect(base_user.email).to be_nil
      end
    end
  end

  describe '#allowed?' do
    let(:context) { create(:'account_service/context') }
    let(:context_id) { context.id }

    before do
      allow(AccountService::Role).to receive(:permissions).with(principal: user, context:)
        .and_return(%w[foo bar])
    end

    it 'checks if any permission applies in the given context' do
      expect(base_user.allowed?('foo')).to be(true)
      expect(base_user.allowed?('bar')).to be(true)
      expect(base_user.allowed?('baz')).to be(false)
    end
  end

  describe '#allowed_any?' do
    let(:context) { create(:'account_service/context') }
    let(:context_id) { context.id }

    before do
      allow(AccountService::Role).to receive(:permissions).with(principal: user, context:)
        .and_return(%w[foo bar])
    end

    it 'checks if any permission applies in the given context' do
      expect(base_user.allowed_any?('bar', 'baz')).to be(true)
      expect(base_user.allowed_any?('foo')).to be(true)
      expect(base_user.allowed_any?('baz', 'bay')).to be(false)
    end
  end

  describe '#preferences' do
    it 'returns the user preferences with indiffren access' do
      expect(base_user.preferences[:abc]).to be(true)
      expect(base_user.preferences['abc']).to be(true)
    end
  end

  describe '#feature?' do
    let(:context) { create(:'account_service/context') }
    let(:context_id) { context.id }
    let(:user) { create(:'account_service/user') }

    it 'looks up features for user and context' do
      allow(AccountService::Feature).to receive(:lookup).and_return(AccountService::Feature.all)

      base_user.feature?('foo')

      expect(AccountService::Feature).to have_received(:lookup).with(owner: user, context:)
    end

    it 'looks a specific feature' do
      create(:'account_service/feature', name: 'foo', context:)

      expect(base_user.feature?('foo')).to be(true)
      expect(base_user.feature?('bar')).to be(false)
    end
  end
end
