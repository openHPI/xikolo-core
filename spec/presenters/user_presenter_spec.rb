# frozen_string_literal: true

require 'spec_helper'

describe UserPresenter do
  subject(:presenter) { described_class.new(user) }

  let(:user) { create(:'account_service/user') }

  before do
    user.primary_email.update(address: 'primary@example.com')
    create(:'account_service/email', :confirmed, user:, address: 'secondary@example.com')
    create(:'account_service/email', :confirmed, address: 'not_from_the_user@example.com')
  end

  describe '#all_emails' do
    subject(:emails) { presenter.all_emails }

    it 'includes all emails for the user' do
      expect(emails.pluck(:address)).to eq %w[primary@example.com secondary@example.com]
    end
  end
end
