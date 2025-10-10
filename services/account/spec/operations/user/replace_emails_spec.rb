# frozen_string_literal: true

require 'spec_helper'

describe User::ReplaceEmails, type: :operation do
  subject(:operation) { described_class.new(user, emails) }

  let(:user) { create(:'account_service/user', :unconfirmed) }
  let(:emails) { [] }
  let!(:primary_email) { user.primary_email }
  let!(:confirmed_email) { create(:'account_service/email', user:, address: 'old.confirmed@email.com', confirmed: true) }
  let!(:unconfirmed_email) { create(:'account_service/email', user:, address: 'old.unconfirmed@email.com') }

  describe 'with a valid email address' do
    let(:emails) { [{address: 'new@email.com', primary: true, confirmed: true}] }

    it 'deletes existing email records for the user' do
      expect { operation.call }.to change { Email.exists?(id: [primary_email, confirmed_email, unconfirmed_email]) }.from(true).to(false)
    end

    it 'creates a new (primary, confirmed) email record, and returns it with the correct attributes' do
      emails = operation.call

      expect(emails.size).to eq 1
      expect(emails.first.attributes).to include(
        'user_id' => user.id,
        'address' => 'new@email.com',
        'primary' => true,
        'confirmed' => true
      )
    end
  end

  describe 'with multiple valid email addresses' do
    let(:emails) do
      [
        {address: 'new.unconfirmed@email.com'},
        {address: 'new.confirmed@email.com', confirmed: true},
        {address: 'new.primary@email.com', primary: true, confirmed: true},
      ]
    end

    it 'deletes existing email records for the user' do
      expect { operation.call }.to change { Email.exists?(id: [primary_email, confirmed_email, unconfirmed_email]) }.from(true).to(false)
    end

    it 'creates new email records, and returns them with the correct attributes' do
      emails = operation.call

      new_primary = emails.find_by(address: 'new.primary@email.com')
      new_confirmed = emails.find_by(address: 'new.confirmed@email.com')
      new_unconfirmed = emails.find_by(address: 'new.unconfirmed@email.com')

      expect(emails.size).to eq(3)

      expect(new_primary).to be_a Email
      expect(new_primary.attributes).to include(
        'user_id' => user.id,
        'primary' => true,
        'confirmed' => true
      )

      expect(new_confirmed).to be_a Email
      expect(new_confirmed.attributes).to include(
        'user_id' => user.id,
        'confirmed' => true
      )
      expect(new_confirmed['primary']).to be_falsey

      expect(new_unconfirmed).to be_a Email
      expect(new_unconfirmed['user_id']).to eq(user.id)
      expect(new_unconfirmed['primary']).to be_falsey
      expect(new_unconfirmed['confirmed']).to be_falsey
    end
  end

  shared_examples_for 'an invalid email address replacement operation' do |error|
    it 'does not delete existing email records' do
      expect { operation.call }.to raise_error(error) do
        expect(Email.exists?(primary_email.id)).to be(true)
        expect(Email.exists?(confirmed_email.id)).to be(true)
        expect(Email.exists?(unconfirmed_email.id)).to be(true)
      end
    end
  end

  describe 'with an empty email list' do
    let(:emails) { [] }

    it_behaves_like 'an invalid email address replacement operation', User::ReplaceEmails::EmptyEmailsError
  end

  describe 'with an empty email address' do
    let(:emails) { [{address: '', primary: true, confirmed: true}] }

    it_behaves_like 'an invalid email address replacement operation', ActiveRecord::RecordInvalid

    it 'raises an ActiveRecord::RecordInvalid error and returns the error object' do
      expect { operation.call }.to raise_error(ActiveRecord::RecordInvalid) do |error|
        expect(error.record.errors[:address]).to eq ["can't be blank", 'is invalid']
      end
    end
  end

  describe 'with an invalid email address' do
    let(:emails) { [{address: 'invalid-email', primary: true, confirmed: true}] }

    it_behaves_like 'an invalid email address replacement operation', ActiveRecord::RecordInvalid

    it 'raises an ActiveRecord::RecordInvalid error and returns the error object' do
      expect { operation.call }.to raise_error(ActiveRecord::RecordInvalid) do |error|
        expect(error.record.errors[:address]).to eq ['is invalid']
      end
    end
  end

  describe 'with an unconfirmed primary email address' do
    let(:emails) { [{address: 'new@email.com', primary: true}] }

    it_behaves_like 'an invalid email address replacement operation', ActiveRecord::RecordInvalid

    it 'raises an ActiveRecord::RecordInvalid error and returns the error object' do
      expect { operation.call }.to raise_error(ActiveRecord::RecordInvalid) do |error|
        expect(error.record.errors[:primary]).to eq ['unconfirmed']
      end
    end
  end

  describe 'with a confirmed, but not primary email address' do
    let(:emails) { [{address: 'new@email.com', confirmed: true}] }

    it_behaves_like 'an invalid email address replacement operation', User::ReplaceEmails::InvalidEmailsError
  end

  describe 'with a valid, but unconfirmed email address' do
    let(:emails) { [{address: 'new@email.com'}] }

    it_behaves_like 'an invalid email address replacement operation', User::ReplaceEmails::InvalidEmailsError
  end

  describe 'with both valid and invalid email addresses' do
    let(:emails) do
      [
        {address: 'new.primary@email.com', primary: true, confirmed: true},
        {address: 'invalid-email', confirmed: true},
      ]
    end

    it_behaves_like 'an invalid email address replacement operation', ActiveRecord::RecordInvalid

    it 'raises an ActiveRecord::RecordInvalid error and returns the error object' do
      expect { operation.call }.to raise_error(ActiveRecord::RecordInvalid) do |error|
        expect(error.record.errors[:address]).to eq ['is invalid']
      end
    end
  end

  describe 'with multiple valid primary email addresses' do
    let(:emails) do
      [
        {address: 'new.primary@email.com', primary: true, confirmed: true},
        {address: 'another.primary@email.com', primary: true, confirmed: true},
      ]
    end

    it_behaves_like 'an invalid email address replacement operation', User::ReplaceEmails::InvalidEmailsError
  end
end
