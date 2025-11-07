# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::Treatment, type: :model do
  subject(:treatment) { create(:'account_service/treatment') }

  it do
    expect(treatment).to accept_values_for :name,
      'treatment',
      'treatm3nt'
  end

  it do
    expect(treatment).not_to accept_values_for :name,
      nil,
      '',
      'treat.ment',
      '///33444'
  end

  describe '#name' do
    it 'is unique' do
      expect do
        create(:'account_service/treatment', name: treatment.name)
      end.to raise_error(ActiveRecord::RecordInvalid, /Name exists/)
    end
  end

  describe '#consent_manager' do
    it 'allows specific keys only, requiring a type' do
      expect(treatment).not_to accept_values_for :consent_manager,
        {'type' => '', 'consent_url' => ''},
        {'type' => '', 'consent_url' => 'https://example.com/consents'},
        {'different_key' => 'external', 'consent_url' => 'https://example.com/consents'}
      expect(treatment).to accept_values_for :consent_manager,
        {},
        {'type' => 'external', 'consent_url' => ''},
        {'consent_url' => '', 'type' => 'external'},
        {'type' => 'external', 'consent_url' => 'https://example.com/consents'}
    end
  end

  describe '#group' do
    it 'returns the correct group' do
      expect(treatment.group).to eq AccountService::Group.find_by(name: "treatment.#{treatment.name}")
    end

    it 'creates the feature group when creating the treatment' do
      expect { treatment }.to change(AccountService::Group, :count).by(1)
    end

    it 'creates the correct feature flipper when creating the treatment' do
      expect { treatment }.to change(AccountService::Feature, :count).by(1)
      expect(AccountService::Feature.find_by(name: "treatment.#{treatment.name}").owner).to eq(treatment.group)
    end
  end
end
