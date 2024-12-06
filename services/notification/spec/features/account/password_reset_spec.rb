# frozen_string_literal: true

require 'spec_helper'

describe 'Account Password Reset Email', type: :feature do
  before do
    Msgr.client.start
    Stub.request(
      :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b'
    ).to_return Stub.json({
      id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      display_name: 'John Smith',
      email: 'john@example.de',
      language: 'en',
    })
    Stub.request(
      :account, :get, '/password_resets/abc'
    ).to_return Stub.json({
      token: 'abc',
      user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
    })
  end

  let(:password_reset_url) { 'https://xikolo.de/reset_password' }

  it 'sends a password reset mail' do
    Msgr.publish({
      user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      token: 'abc',
      url: password_reset_url,
    }, to: 'xikolo.account.password_reset.notify')

    Msgr::TestPool.run

    expect(mail).to be_a Mail::Message
    expect(mail.to).to include 'john@example.de'
    expect(mail.from).to eql ['no-reply@xikolo.de']

    expect(mail.html).to be_present
    expect(mail.html).to include password_reset_url

    expect(mail.text).to be_present
    expect(mail.text).to include password_reset_url
  end

  it 'ignores resets for deleted users' do
    Stub.request(
      :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b'
    ).to_return Stub.json({
      id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      display_name: 'Deleted User',
      email: nil,
      language: 'en',
    })
    Stub.request(
      :account, :get, '/password_resets/abc'
    ).to_return Stub.json({
      token: 'abc',
      user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
    })
    Msgr.publish({
      user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      token: 'abc',
      url: password_reset_url,
    }, to: 'xikolo.account.password_reset.notify')

    Msgr::TestPool.run

    expect(mail).to be_nil
  end

  describe 'localization' do
    context 'for a German user' do
      before do
        Stub.request(
          :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b'
        ).to_return Stub.json({
          id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
          display_name: 'John Smith',
          email: 'john@example.de',
          language: 'de',
        })
        Stub.request(
          :account, :get, '/password_resets/abc'
        ).to_return Stub.json({
          token: 'abc',
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
        })
      end

      it 'has German text' do
        Msgr.publish({
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
          token: 'abc',
          url: password_reset_url,
        }, to: 'xikolo.account.password_reset.notify')

        Msgr::TestPool.run

        expect(mail.subject).to eq 'Passwort zurücksetzen für Ihr Xikolo Benutzerkonto'
        expect(mail.html).to include 'Klicken Sie den untenstehenden Button, um das Passwort nun zurückzusetzen.'
        expect(mail.text).to include 'Klicken Sie den untenstehenden Button, um das Passwort nun zurückzusetzen.'
      end
    end
  end
end
