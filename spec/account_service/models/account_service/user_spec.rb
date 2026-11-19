# frozen_string_literal: true

require 'spec_helper'

describe AccountService::User, type: :model do
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

  it 'exposes profile enums' do
    expect(described_class.genders.keys).to include('male', 'female', 'diverse', 'undisclosed')
    expect(described_class.statuses.keys).to include('school_student', 'university_student', 'teacher', 'other')
  end

  describe '#anonymous' do
    before { described_class.anonymous }

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

        expect(described_class.find(user.id).language).to be_nil
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
          u = described_class.find user.id
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
      expect(described_class.created_last_day.count).to be 1
    end
  end

  describe '#created_last_7days' do
    before do
      create(:'account_service/user')
      create(:'account_service/user', created_at: 2.days.ago)
      create(:'account_service/user', created_at: 8.days.ago)
    end

    it 'filters old users' do
      expect(described_class.created_last_7days.count).to be 2
    end
  end

  describe '#email' do
    before { user }

    context 'when primary email changes' do
      subject(:update_email) do
        new_email.update! primary: true
        user.reload
      end

      let!(:new_email) { create(:'account_service/email', :confirmed, user:) }

      before { expect(user.email).not_to eq new_email.address }

      it 'changes user#email' do
        expect { update_email }.to \
          change(user, :email).from(user.email).to(new_email.address)
      end
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

  describe '#underage?' do
    subject { user.underage? }

    context 'without a birthdate' do
      it { is_expected.to be false }
    end

    context 'when the user turns 16 today' do
      let(:attributes) { {born_at: 16.years.ago.to_date} }

      it { is_expected.to be false }
    end

    context 'when the user turned 16 yesterday' do
      let(:attributes) { {born_at: (16.years.ago - 1.day).to_date} }

      it { is_expected.to be false }
    end

    context 'when the user turns 16 tomorrow' do
      let(:attributes) { {born_at: (16.years.ago + 1.day).to_date} }

      it { is_expected.to be true }
    end
  end

  describe '#guardian_consent_required?' do
    subject { user.guardian_consent_required? }

    context 'when the user is of age' do
      let(:attributes) { {born_at: 20.years.ago} }

      it { is_expected.to be false }
    end

    context 'when the user is underage' do
      let(:attributes) { {born_at: 12.years.ago} }

      it { is_expected.to be true }

      context 'and a guardian consented' do
        let(:attributes) { super().merge(guardian_consent_at: 1.day.ago) }

        it { is_expected.to be false }
      end
    end

    context 'when the birthdate is corrected to an underage one' do
      let(:attributes) { {born_at: 20.years.ago} }

      before { user.update!(born_at: 12.years.ago) }

      it { is_expected.to be true }
    end
  end

  describe '#guardian_consent=' do
    it 'records when the consent was given' do
      user.update!(guardian_consent: true)

      expect(user.guardian_consent_at).to be_within(1.minute).of(Time.zone.now)
    end

    it 'keeps the timestamp of the first consent' do
      user.update!(guardian_consent_at: 2.days.ago)

      expect { user.update!(guardian_consent: true) }.not_to change(user, :guardian_consent_at)
    end

    # Submitted as a string by the registration form, where a checkbox that
    # was not ticked must not count as consent.
    it 'records nothing when the consent was not given' do
      ['false', '0', '', nil].each do |value|
        user.update!(guardian_consent: value)

        expect(user.guardian_consent_at).to be_nil
      end
    end
  end

  describe '.with_embedded_resources' do
    subject(:resource) { records[4] }

    let!(:users) do
      create_list(:'account_service/user', 10)
    end

    let(:user) { users[4] }
    let(:query) { described_class.with_embedded_resources }

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

  describe '#affiliated' do
    let(:attributes) { {affiliated: true} }

    before { user }

    it 'is true' do
      expect(user.affiliated).to be true
    end

    it 'creates a membership in the affiliated group' do
      expect(AccountService::Membership.where(group: AccountService::Group.affiliated_users).count).to eq 1
    end
  end

  describe '#ban' do
    let(:session) { create(:'account_service/session', user:) }

    before do
      session
    end

    it 'marks user as banned and destroys all sessions' do
      expect { user.ban }
        .to change { user.reload.banned? }.from(false).to(true)
        .and change { user.reload.ban_count }.from(0).to(1)
        .and change(AccountService::Session, :count).from(1).to(0)
    end
  end

  describe '#unban' do
    let(:user) { create(:'account_service/user', :banned) }

    it 'marks user as not banned and keeps ban count' do
      expect { user.unban }
        .to change { user.reload.banned? }.from(true).to(false)

      expect(user.reload.ban_count).to eq 1
    end
  end

  describe '#grant_top_talent!' do
    subject(:grant) { user.grant_top_talent!(source: 'admin') }

    it 'marks the user as top talent and creates an active record' do
      expect { grant }
        .to change { user.reload.top_talent? }.from(false).to(true)
        .and change { UserTopTalent.where(user:).count }.from(0).to(1)

      record = UserTopTalent.where(user:).first
      expect(record.revoked_at).to be_nil
      expect(record.source).to eq 'admin'
    end

    it 'is idempotent' do
      user.grant_top_talent!(source: 'admin')

      expect { user.grant_top_talent!(source: 'admin') }.not_to change { UserTopTalent.where(user:).count }
    end
  end

  describe '#revoke_top_talent!' do
    subject(:revoke) { user.revoke_top_talent!(source: 'admin') }

    before { user.grant_top_talent!(source: 'admin') }

    it 'unmarks the user but keeps the (revoked) record' do
      expect { revoke }.to change { user.reload.top_talent? }.from(true).to(false)

      expect(UserTopTalent.where(user:).count).to eq 1
      record = UserTopTalent.where(user:).first
      expect(record.revoked_at).to be_present
      expect(UserTopTalent.where(user:).active.exists?).to be false
    end

    it 'can be granted again, reusing the same record' do
      revoke

      expect { user.grant_top_talent!(source: 'admin') }
        .to change { user.reload.top_talent? }.from(false).to(true)

      expect(UserTopTalent.where(user:).count).to eq 1
      expect(UserTopTalent.where(user:).first.revoked_at).to be_nil
    end
  end

  describe '#top_talent?' do
    context 'with no records' do
      it { expect(user.top_talent?).to be false }
    end

    context 'with an active record' do
      before { user.grant_top_talent!(source: 'admin') }

      it { expect(user.top_talent?).to be true }
    end

    context 'with only a revoked record' do
      before do
        user.grant_top_talent!(source: 'admin')
        user.revoke_top_talent!(source: 'admin')
      end

      it { expect(user.top_talent?).to be false }
    end
  end

  describe '#all_groups' do
    subject(:groups) { user.all_groups }

    it 'includes all users group' do
      expect(groups).to include AccountService::Group.all_users
    end

    it 'includes active users group' do
      expect(groups).to include AccountService::Group.active_users
    end

    it 'includes confirmed users group' do
      expect(groups).to include AccountService::Group.confirmed_users
    end

    it 'does not include unconfirmed users group' do
      expect(groups).not_to include AccountService::Group.unconfirmed_users
    end

    it 'does not include archived users group' do
      expect(groups).not_to include AccountService::Group.archived_users
    end

    context 'unconfirmed user' do
      let(:user) { create(:'account_service/user', :unconfirmed, attributes) }

      before do
        expect(user).not_to be_confirmed
      end

      it 'includes all users group' do
        expect(groups).to include AccountService::Group.all_users
      end

      it 'includes unconfirmed users group' do
        expect(groups).to include AccountService::Group.unconfirmed_users
      end

      it 'does not include active users group' do
        expect(groups).not_to include AccountService::Group.active_users
      end

      it 'does not include confirmed users group' do
        expect(groups).not_to include AccountService::Group.confirmed_users
      end

      it 'does not include archived users group' do
        expect(groups).not_to include AccountService::Group.archived_users
      end
    end

    context 'archived user' do
      let(:attributes) { {archived: true} }

      before do
        expect(user).to be_archived
      end

      it 'includes all users group' do
        expect(groups).to include AccountService::Group.all_users
      end

      it 'includes archived users group' do
        expect(groups).to include AccountService::Group.archived_users
      end

      it 'includes confirmed users group' do
        expect(groups).to include AccountService::Group.confirmed_users
      end

      it 'does not include active users group' do
        expect(groups).not_to include AccountService::Group.active_users
      end

      it 'does not include unconfirmed users group' do
        expect(groups).not_to include AccountService::Group.unconfirmed_users
      end
    end

    context 'banned user' do
      subject(:user) { create(:'account_service/user', :banned) }

      before do
        expect(user).to be_banned
      end

      it 'includes all users group' do
        expect(groups).to include AccountService::Group.all_users
      end

      it 'includes confirmed users group' do
        expect(groups).to include AccountService::Group.confirmed_users
      end

      it 'does not include active users group' do
        expect(groups).not_to include AccountService::Group.active_users
      end

      it 'does not include archived users group' do
        expect(groups).not_to include AccountService::Group.archived_users
      end

      it 'does not include unconfirmed users group' do
        expect(groups).not_to include AccountService::Group.unconfirmed_users
      end
    end
  end
end
