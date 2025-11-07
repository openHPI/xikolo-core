# frozen_string_literal: true

require 'spec_helper'

describe 'Account Welcome Email', type: :feature do
  let(:welcome_email_url) { 'https://xikolo.de/welcome_email' }
  let(:user_response) do
    Stub.json({
      id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      display_name: 'John Smith',
      email: 'john@example.de',
      language: user_language,
      features_url: '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b/features',
    })
  end
  let(:user_language) { 'en' }

  before do
    Msgr.client.start
    Stub.request(
      :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b'
    ).to_return user_response

    Stub.request(
      :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b/features'
    ).to_return Stub.json({
      'account.profile.mandatory_completed': 't',
    })
  end

  shared_examples_for 'a welcome email' do
    it 'send a welcome email' do
      expect(mail).to be_a Mail::Message
      expect(mail.to).to include 'john@example.de'
      expect(mail.from).to eql ['no-reply@xikolo.de']

      expect(mail.html).to be_present
      expect(mail.text).to be_present
    end
  end

  describe 'confirmation_url' do
    context 'when the confirmation_url is on the payload' do
      before do
        Msgr.publish({
          confirmation_url: welcome_email_url,
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
        }, to: 'xikolo.web.account.sign_up')

        Msgr::TestPool.run
      end

      it_behaves_like 'a welcome email'

      it 'has the confirmation_url on the email' do
        expect(mail.html).to include welcome_email_url
        expect(mail.text).to include welcome_email_url
      end
    end

    context 'when the confirmation_url is not on the payload' do
      before do
        Msgr.publish({
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
        }, to: 'xikolo.web.account.sign_up')

        Msgr::TestPool.run
      end

      it_behaves_like 'a welcome email'

      it 'does not have the confirmation_url on the email' do
        expect(mail.html).not_to include welcome_email_url
        expect(mail.text).not_to include welcome_email_url
      end
    end
  end

  describe 'mandatory fields on the user profile' do
    context 'when the user needs to fill mandatory fields on their profile' do
      before do
        Msgr.publish({
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
        }, to: 'xikolo.web.account.sign_up')

        Msgr::TestPool.run
      end

      it_behaves_like 'a welcome email'

      it { expect(mail.html).not_to include I18n.t('account_mailer.welcome_email.step_1') }
    end

    context 'when the user does not need to fill mandatory fields on their profile' do
      before do
        Stub.request(
          :account, :get, '/users/c088d006-8886-4b3c-a6ac-d45f168abc5b/features'
        ).to_return user_response

        Msgr.publish({
          user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
        }, to: 'xikolo.web.account.sign_up')

        Msgr::TestPool.run
      end

      it_behaves_like 'a welcome email'

      it { expect(mail.html).to include I18n.t('account_mailer.welcome_email.step_1') }
    end
  end

  describe 'localization' do
    before do
      Msgr.publish({
        user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      }, to: 'xikolo.web.account.sign_up')

      Msgr::TestPool.run
    end

    context 'for a German user' do
      let(:user_language) { 'de' }

      it_behaves_like 'a welcome email'

      it 'has German text' do
        expect(mail.subject).to eq 'Willkommen bei Xikolo'
        expect(mail.html).to include 'Sie erhalten diese E-Mail, weil Sie ein neues Konto bei Xikolo registriert haben.'
        expect(mail.text).to include 'Sie erhalten diese E-Mail, weil Sie ein neues Konto bei Xikolo registriert haben.'
      end
    end
  end

  context 'with deleted user' do
    let(:user_response) { Stub.response(status: 404) }

    it 'does not send an email' do
      Msgr.publish({
        user_id: 'c088d006-8886-4b3c-a6ac-d45f168abc5b',
      }, to: 'xikolo.web.account.sign_up')

      Msgr::TestPool.run

      expect(mails).to be_empty
    end
  end
end
