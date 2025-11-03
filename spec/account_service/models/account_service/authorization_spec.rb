# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Authorization, type: :model do
  subject(:authorization) { create(:'account_service/authorization', attributes) }

  let(:attributes) { {} }

  describe '#info' do
    subject { authorization.info }

    describe 'update' do
      subject { authorization.reload.info }

      before { authorization.update! info: {'key' => false} }

      it { is_expected.to eq 'key' => false }
    end
  end

  describe '#update' do
    subject(:update) { authorization.update! uid: 1234 }

    it 'does trigger a provider update' do
      expect(AccountService::Provider).to receive(:update).with(authorization)
      update
    end
  end

  describe '#destroy' do
    before { authorization }

    it 'does not trigger a provider update' do
      expect(AccountService::Provider).not_to receive(:update)
      authorization.destroy
    end
  end
end
