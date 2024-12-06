# frozen_string_literal: true

require 'spec_helper'

describe NotificationUserSettingsHelper, type: :helper do
  describe 'hash_email' do
    subject { hash_email id: email_id, user_id: }

    let(:user_id) { '11111111-2222-3333-4444-555555555555' }
    let(:email_id) { '66666666-7777-8888-9999-000000000000' }

    it { is_expected.to eq '88d9a72789e4c8c58b172ac6703c915d89af58c52f62eb40af175a4d4751e21a' }
  end
end
