# frozen_string_literal: true

require 'spec_helper'

describe 'Email Address Confirmation Email', type: :feature do
  let(:confirm_email_url) { 'https://xikolo.de/confirm_email' }
  let(:user_language) { 'en' }

  before do
    Msgr.client.start

    Stub.request(
      :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b'
    ).to_return Stub.json({
      id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      display_name: 'John Smith',
      email: 'john@example.de',
      language: user_language,
      email_url: '/account_service/users/c088d006-8886-4b3c-a6ac-d45f168abc5b/emails/{id}',
    })
    Stub.request(
      :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b/emails/7dbf9da5-f3de-4b83-b5af-299d3fbf9e11'
    ).to_return Stub.json({
      id: '7dbf9da5-f3de-4b83-b5af-299d3fbf9e11',
      user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      address: 'john@theuniverse.com',
      primary: true,
      confirmed: false,
    })
  end

  it 'send an address confirmation mail' do
    Msgr.publish({
      id:      '7dbf9da5-f3de-4b83-b5af-299d3fbf9e11',
        url:     confirm_email_url,
        user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
    }, to: 'xikolo.account.email.confirm')

    Msgr::TestPool.run

    expect(mail).to be_a Mail::Message
    expect(mail.to).to include 'john@theuniverse.com'
    expect(mail.from).to eql ['no-reply@xikolo.de']

    expect(conv_str(mail.html_part)).to be_present
    expect(conv_str(mail.html_part)).to include confirm_email_url

    expect(conv_str(mail.text_part)).to be_present
    expect(conv_str(mail.text_part)).to include confirm_email_url
  end

  describe 'localization' do
    context 'for a German user' do
      let(:user_language) { 'de' }

      it 'has German text' do
        Msgr.publish({
          id:      '7dbf9da5-f3de-4b83-b5af-299d3fbf9e11',
          url:     confirm_email_url,
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
        }, to: 'xikolo.account.email.confirm')

        Msgr::TestPool.run

        expect(mail.subject).to eq 'Bitte Bestätigen Sie Ihre E-Mail'
        expect(conv_str(mail.html_part)).to include 'Sie bekommen diese E-Mail, da Sie eine neue E-Mail-Adresse zu Ihrem Konto bei Xikolo hinzugefügt haben.'
        expect(conv_str(mail.text_part)).to include 'Sie bekommen diese E-Mail, da Sie eine neue E-Mail-Adresse zu Ihrem Konto bei Xikolo hinzugefügt haben.'
      end
    end
  end
end
