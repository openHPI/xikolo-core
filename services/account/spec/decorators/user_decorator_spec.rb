# frozen_string_literal: true

require 'spec_helper'

describe UserDecorator, type: :decorator do
  let(:user) { create(:user) }
  let(:decorator) { described_class.new(user) }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'includes the correct properties' do
      expect(payload.keys).to match_array %w[
        id
        email
        display_name
        admin
        language
        preferred_language
        timezone
        avatar_url
        born_at
        confirmed
        anonymous
        archived
        accepted_policy_version
        policy_accepted
        status
        gender
        country
        state
        city

        name
        full_name
        affiliated
        affiliation
        password_digest
        created_at
        updated_at

        self_url
        email_url
        emails_url
        flippers_url
        features_url
        groups_url
        permissions_url
        preferences_url
        profile_url
        consents_url
      ]
    end

    it { is_expected.to include 'id' => user.id }
    it { is_expected.to include 'email' => user.email }
    it { is_expected.to include 'display_name' => user.display_name }
    it { is_expected.to include 'admin' => false }
    it { is_expected.to include 'timezone' => user.timezone }
    it { is_expected.to include 'confirmed' => user.confirmed? }
    it { is_expected.to include 'anonymous' => false }
    it { is_expected.to include 'archived' => user.archived? }

    it { is_expected.to include 'language' => 'en' }
    it { is_expected.to include 'preferred_language' => 'en' }

    it { is_expected.to include 'policy_accepted' => user.policy_accepted? }
    it { is_expected.to include 'accepted_policy_version' => user.accepted_policy_version }

    it { is_expected.to include 'name' => user.name }
    it { is_expected.to include 'full_name' => user.full_name }
    it { is_expected.to include 'affiliated' => user.affiliated? }
    it { is_expected.to include 'password_digest' => user.password_digest }
    it { is_expected.to include 'created_at' => user.created_at.iso8601 }
    it { is_expected.to include 'updated_at' => user.updated_at.iso8601 }

    it { is_expected.to include 'self_url' => user_url(user) }
    it { is_expected.to include 'groups_url' => groups_url(user:) }
    it { is_expected.to include 'profile_url' => user_profile_url(user) }
    it { is_expected.to include 'consents_url' => user_consents_url(user) }

    context 'without preferred language' do
      let(:user) { create(:user, language: nil) }

      it { is_expected.to include 'language' => 'en' }
      it { is_expected.to include 'preferred_language' => nil }
    end

    context 'with anonymous user' do
      let(:user) { User.anonymous }

      it { is_expected.to include 'anonymous' => true }
    end
  end
end
