# frozen_string_literal: true

require 'spec_helper'

describe User, type: :model do
  subject(:user) { create(:'account_service/user', attributes) }

  let(:attributes) { {} }

  it do
    expect(user).not_to accept_values_for :full_name,
      '',
      'a' * 201,
      'Sky/Hacker',
      'B"Master"',
      '"',
      '/'
  end

  it do
    expect(user).to accept_values_for :full_name,
      "NIKOS KIRIAKOS PRESIDENT ADJ SCIENTIFIC RESEARCH CENTER AND CENTER FOR BIBLICAL O'Connor",
      'Karl-Theodor Maria Nikolaus Johann Jacob Philipp Franz Joseph Sylvester Buhl-Freiherr von und zu Guttenberg'
  end

  it do
    expect(user).not_to accept_values_for :display_name,
      'Sky/Hacker',
      'B"Master"',
      '"',
      '/'
  end

  it do
    expect(user).to accept_values_for :display_name,
      "John O'Hara, the $$-Junk13 ^^"
  end

  it { expect(user).to accept_values_for :language, 'en', 'de' }
  it { expect(user).not_to accept_values_for :language, 'it', 'pt-BR' }

  it { is_expected.to respond_to(:email) }
  it { is_expected.to be_valid }

  describe '#anonymous' do
    before { User.anonymous }

    let(:anon) { build(:'account_service/user', anonymous: true) }

    it 'allows only one record' do
      expect(anon).not_to be_valid
    end
  end

  describe '#full_name' do
    subject { super().full_name }

    context 'when created with full name' do
      let(:attributes) { {full_name: 'Jane Doe'} }

      it { is_expected.to eq 'Jane Doe' }
    end
  end

  describe '#language' do
    subject { super().language }

    it { is_expected.to eq 'en' }

    context 'when set to nil' do
      before { user.update! language: nil }

      it { is_expected.to be_nil }
    end

    context 'when the user has an invalid language' do
      before { Xikolo.config.locales['available'] = %w[en de] }

      it 'sanitizes the language when the user is fetched' do
        user = build(:'account_service/user', language: 'zh')
        user.save!(validate: false)

        expect(User.find(user.id).language).to be_nil
      end
    end
  end

  describe '#preferences' do
    subject { user.preferences }

    describe 'update' do
      subject { user.reload.preferences }

      before { user.update! preferences: {'key' => false} }

      it { is_expected.to include 'key' => 'false' }
    end

    describe 'other changer' do
      before { user.update! preferences: {'key' => false} }

      it 'does not reset hash when updating other attributes' do
        expect do
          u = User.find user.id
          u.update! password: 'abcdefgh', password_confirmation: 'abcdefgh'
        end.not_to change { user.reload.preferences }
      end
    end
  end

  describe '#password=' do
    before { user }

    context 'when nil' do
      it 'does NOT reset/change digest' do
        expect do
          user.password = nil
          user.save!
        end.not_to change { user.reload.password_digest }
      end
    end

    context 'when non-blank string' do
      it 'changes password_digest' do
        expect do
          user.password = 'catcatcat'
          user.save!
        end.to change { user.reload.password_digest }
      end

      it 'allows to authenticate with new password' do
        user.update! password: 'catcatcat'
        expect(user.authenticate('catcatcat')).to eq user
      end
    end

    context 'with less than 8 characters' do
      it 'raise a validation error' do
        expect do
          user.update! password: '1234567'
        end.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'with more than 72 characters' do
      it 'raise a validation error' do
        expect do
          user.update! password: 'a' * 73
        end.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'containing an e-mail of the user' do
      it 'raise a validation error' do
        expect do
          user.update! password: "CAT#{user.email}DOG"
        end.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#password_digest=' do
    before { user }

    context 'when nil' do
      it 'does NOT reset/change digest' do
        expect do
          user.password_digest = nil
          user.save!
        end.not_to change { user.reload.password_digest }
      end
    end

    context 'when empty string' do
      it 'does NOT reset/change digest' do
        expect do
          user.password_digest = ''
          user.save!
        end.not_to change { user.reload.password_digest }
      end
    end
  end

  describe '#authenticate' do
    subject { user.authenticate password }

    let(:attributes) do
      super().merge password_digest: BCrypt::Password.create('secret')
    end

    context 'with valid credential' do
      let(:password) { 'secret' }

      it { is_expected.to eq user }
    end
  end

  describe '#created_last_day' do
    before do
      create(:'account_service/user')
      create(:'account_service/user', created_at: 2.days.ago)
    end

    it 'filters old users' do
      expect(User.created_last_day.count).to be 1
    end
  end

  describe '#created_last_7days' do
    before do
      create(:'account_service/user')
      create(:'account_service/user', created_at: 2.days.ago)
      create(:'account_service/user', created_at: 8.days.ago)
    end

    it 'filters old users' do
      expect(User.created_last_7days.count).to be 2
    end
  end

  describe '#create' do
    describe 'event notify' do
      subject(:user) do
        ActiveRecord::Base.transaction do
          create(:'account_service/user').tap do |user|
            create(:'account_service/email', user:)
          end
        end
      end

      let(:record) { User.first }
      let(:email) { Email.first }

      it 'publishes an event' do
        expect(Msgr).to receive :publish do |payload, opts|
          expect(opts).to eq to: 'xikolo.account.user.create'

          expect(payload).to include \
            'id' => record.id,
            'email' => email.address
        end

        user
      end
    end
  end

  describe '#update' do
    before { user }

    it 'publishes an event' do
      expect(Msgr).to receive(:publish) do |payload, opts|
        expect(opts).to eq to: 'xikolo.account.user.update'
        expect(payload).to eq user.decorate.as_event
        expect(payload).to include 'full_name' => 'Luke Skywalker'
      end

      user.update! full_name: 'Luke Skywalker'
    end
  end

  describe '#email' do
    before { user }

    context 'when primary email changes' do
      subject(:update_email) do
        new_email.update! primary: true
        user.primary_email.reload
      end

      let!(:new_email) { create(:'account_service/email', :confirmed, user:) }

      before { expect(user.email).not_to eq new_email.address }

      it 'changes user#email' do
        expect { update_email }.to \
          change(user, :email).from(user.email).to(new_email.address)
      end

      it 'publishes an event' do
        allow(Msgr).to receive(:publish)

        expect(Msgr).to receive(:publish).with(
          anything,
          hash_including(to: 'xikolo.account.user.update')
        ) do |payload, _|
          expect(payload).to eq user.decorate.as_event
          expect(payload).to include 'email' => new_email.address
        end

        update_email
      end
    end
  end

  describe '#destroy' do
    before { user }

    it 'publishes an event' do
      expect(Msgr).to receive(:publish) do |payload, opts|
        expect(opts).to eq to: 'xikolo.account.user.destroy'
        expect(payload).to eq user.decorate.as_event
      end

      user.destroy!
    end
  end

  describe '#policy_accepted?' do
    subject { user.policy_accepted? }

    context 'without policy' do
      it { is_expected.to be_truthy }
    end

    context 'with policy' do
      let!(:policy) { create(:'account_service/policy') }

      it { is_expected.to be_falsy }

      context 'that is accepted' do
        before { user.update! accepted_policy_version: policy.version }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.with_embedded_resources' do
    subject(:resource) { records[4] }

    let!(:users) do
      create_list(:'account_service/user', 10)
    end

    let(:user) { users[4] }
    let(:query) { User.with_embedded_resources }

    # Required to order the records by UUID in same order as created list
    # because all `created_at`s are too similar to have PostgreSQL return
    # the users in same order.
    let(:records) { query.to_a.sort_by {|u| users.index(u) } }

    it 'includes the primary email address' do
      expect(resource[:primary_email_address]).to eq users[4].primary_email.address
    end

    it 'included a policy flag' do
      expect(resource[:policy_accepted]).to be true
    end

    context 'with new policy' do
      before { create(:'account_service/policy') }

      it 'included a policy flag' do
        expect(resource[:policy_accepted]).to be false
      end

      context 'when accepted' do
        before do
          user.update! accepted_policy_version: 1
        end

        it 'included a policy flag' do
          expect(resource[:policy_accepted]).to be true
        end
      end
    end
  end

  describe '#update_profile_completion!' do
    subject(:action) { -> { user.update_profile_completion! } }

    let!(:field1) do
      create(:'account_service/custom_text_field', name: 'fn1', required: true)
    end

    let!(:field2) do
      create(:'account_service/custom_text_field', name: 'fn2', required: true)
    end

    before do
      create(:'account_service/custom_text_field', name: 'fn3', required: false)
    end

    context 'with required fields filled' do
      let(:attributes) { super().merge(completed_profile: false) }

      before do
        field1.update_values(user, ['text'])
        field2.update_values(user, ['text'])
      end

      it do
        expect { action.call }
          .to change { user.features.reload.map(&:name) }
          .from([])
          .to(['account.profile.mandatory_completed'])
      end
    end

    context 'with required fields removed' do
      let(:attributes) { super().merge(completed_profile: true) }

      it do
        expect { action.call }
          .to change { user.features.reload.map(&:name) }
          .from(['account.profile.mandatory_completed'])
          .to([])
      end
    end
  end

  describe '#affiliated' do
    let(:attributes) { {affiliated: true} }

    before { user }

    it 'is true' do
      expect(user.affiliated).to be true
    end

    it 'creates a membership in the affiliated group' do
      expect(Membership.where(group: Group.affiliated_users).count).to eq 1
    end
  end

  describe '#all_groups' do
    subject(:groups) { user.all_groups }

    it 'includes all users group' do
      expect(groups).to include Group.all_users
    end

    it 'includes active users group' do
      expect(groups).to include Group.active_users
    end

    it 'includes confirmed users group' do
      expect(groups).to include Group.confirmed_users
    end

    it 'does not include unconfirmed users group' do
      expect(groups).not_to include Group.unconfirmed_users
    end

    it 'does not include archived users group' do
      expect(groups).not_to include Group.archived_users
    end

    context 'unconfirmed user' do
      let(:user) { create(:'account_service/user', :unconfirmed, attributes) }

      before do
        expect(user).not_to be_confirmed
      end

      it 'includes all users group' do
        expect(groups).to include Group.all_users
      end

      it 'includes unconfirmed users group' do
        expect(groups).to include Group.unconfirmed_users
      end

      it 'does not include active users group' do
        expect(groups).not_to include Group.active_users
      end

      it 'does not include confirmed users group' do
        expect(groups).not_to include Group.confirmed_users
      end

      it 'does not include archived users group' do
        expect(groups).not_to include Group.archived_users
      end
    end

    context 'archived user' do
      let(:attributes) { {archived: true} }

      before do
        expect(user).to be_archived
      end

      it 'includes all users group' do
        expect(groups).to include Group.all_users
      end

      it 'includes archived users group' do
        expect(groups).to include Group.archived_users
      end

      it 'includes confirmed users group' do
        expect(groups).to include Group.confirmed_users
      end

      it 'does not include active users group' do
        expect(groups).not_to include Group.active_users
      end

      it 'does not include unconfirmed users group' do
        expect(groups).not_to include Group.unconfirmed_users
      end
    end
  end
end
