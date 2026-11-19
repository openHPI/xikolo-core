# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Accounts: Create', type: :request do
  subject(:result) { post '/account', params: }

  let(:params) { {user: user_params} }
  let(:user_params) do
    {
      full_name: 'Jane Doe',
      email: 'doe@plattner.de',
      status: 'teacher',
      password: 'secret123',
      password_confirmation: 'secret123',
      language: 'en',
      born_at: '1990-01-20',
    }
  end
  let(:email) { AccountService::Email.find_by!(address: 'doe@plattner.de') }
  let(:new_user) { email.user }

  context 'with complete data' do
    it { is_expected.to redirect_to verify_account_path }

    it 'creates the user with an unconfirmed primary e-mail address' do
      result

      expect(new_user).to have_attributes(
        full_name: 'Jane Doe',
        status: 'teacher',
        language: 'en'
      )
      expect(new_user.born_at.to_date).to eq Date.new(1990, 1, 20)
      expect(new_user.authenticate('secret123')).to be_truthy
      expect(email).to have_attributes(primary: true, confirmed: false)
    end

    it 'triggers a welcome email to be sent out' do
      result

      expect(NotificationService::SendWelcomeEmailJob)
        .to have_been_enqueued
        .with(new_user.id, %r{^http://www.example.com/account/confirm/.+$})
    end

    context 'when there are policies to accept' do
      before do
        create(:'account_service/policy', version: 2)
        create(:'account_service/policy', version: 3)
      end

      it 'marks the latest version as accepted' do
        result

        expect(new_user.accepted_policy_version).to eq 3
      end
    end

    context 'when there is something to consent to' do
      let(:params) { super().merge(consent: ['user_data']) }

      before do
        create(:'account_service/treatment', name: 'user_data')
        create(:'account_service/treatment', name: 'marketing')
      end

      it 'records the consents for all treatments' do
        result

        expect(new_user.consents.map {|consent| [consent.treatment.name, consent.value] })
          .to contain_exactly(['user_data', true], ['marketing', false])
      end
    end

    context 'with a required treatment' do
      before do
        create(:'account_service/treatment', name: 'user_profile', required: true)
      end

      context 'when the user consented' do
        let(:params) { super().merge(consent: %w[user_profile]) }

        it 'creates the user and records the consent' do
          result

          expect(new_user.consents.map {|consent| [consent.treatment.name, consent.value] })
            .to contain_exactly(['user_profile', true])
        end
      end

      context 'when the user did not consent' do
        it 'refuses to create the account' do
          result

          expect(response).to have_http_status :unprocessable_content
          expect(response.body).to include 'We found some errors'
          expect(AccountService::Email.find_by(address: 'doe@plattner.de')).to be_nil
        end

        context 'with another treatment consented to' do
          let(:params) { super().merge(treatments: 'user_profile,marketing', consent: %w[marketing]) }

          before do
            create(:'account_service/treatment', name: 'marketing')
          end

          it 'keeps the given consent ticked when re-rendering the form' do
            result

            page = Capybara.string(response.body)
            expect(page).to have_field('consent_marketing', type: 'checkbox', checked: true)
            expect(page).to have_field('consent_user_profile', type: 'checkbox', checked: false)
          end
        end
      end
    end

    context 'with the guardian consent' do
      context 'when the user is of age' do
        it 'is not recorded' do
          result

          expect(new_user.guardian_consent_at).to be_nil
        end
      end

      context 'without a birthdate' do
        let(:user_params) { super().merge(born_at: '') }

        it 'refuses to create the account, as the birthdate is mandatory' do
          result

          expect(response).to have_http_status :unprocessable_content
          expect(AccountService::Email.find_by(address: 'doe@plattner.de')).to be_nil
        end
      end

      context 'when the user is underage' do
        let(:user_params) { super().merge(born_at: 14.years.ago.to_date.iso8601) }

        context 'when the guardian consent was ticked' do
          let(:user_params) { super().merge(guardian_consent: 'true') }

          it 'creates the user and records when the consent was given' do
            result

            expect(new_user.guardian_consent_at).to be_within(1.minute).of(Time.zone.now)
          end
        end

        context 'when the guardian consent was unticked' do
          let(:user_params) { super().merge(guardian_consent: 'false') }

          it 'refuses to create the account' do
            result

            expect(response).to have_http_status :unprocessable_content
            expect(response.body).to include 'We found some errors'
            expect(AccountService::Email.find_by(address: 'doe@plattner.de')).to be_nil
          end
        end

        context 'when the guardian consent was not submitted at all' do
          it 'refuses to create the account' do
            result

            expect(response).to have_http_status :unprocessable_content
            expect(response.body).to include 'We found some errors'
            expect(AccountService::Email.find_by(address: 'doe@plattner.de')).to be_nil
          end
        end
      end
    end

    context 'with email notifications' do
      context 'when the user agreed to them' do
        let(:params) { super().merge(notification_emails: 'true') }

        it 'enables the global and all event notifications' do
          result

          expect(new_user.preferences).to eq({
            'notification.email.global' => 'true',
            'notification.email.news.announcement' => 'true',
            'notification.email.course.announcement' => 'true',
            'notification.email.pinboard.new_answer' => 'true',
          })
        end
      end

      context 'when the user did not agree to them' do
        it 'leaves email notifications disabled' do
          result

          expect(new_user.preferences).to eq({'notification.email.global' => 'false'})
        end
      end
    end
  end

  context 'with incomplete data' do
    let(:user_params) do
      {
        full_name: 'Jane Doe',
      }
    end

    it 'renders the form again, including errors' do
      result
      expect(response.body).to include 'Create your own account on openHPI.'
      expect(response.body).to include 'We found some errors'
      expect(response.body).to include 'can&#39;t be blank'
    end
  end

  context 'with already known e-mail address' do
    before do
      user = create(:'account_service/user', password: 'secret123')
      user.emails.first.update!(address: 'doe@plattner.de')
    end

    context 'when credentials match' do
      it 'interprets the request as login and sends the user to the dashboard' do
        expect(result).to redirect_to dashboard_path
      end
    end

    context 'when credentials do not match' do
      let(:user_params) do
        super().merge(password: 'anothersecret', password_confirmation: 'anothersecret')
      end

      it 'renders the form again, including an explanatory error' do
        result
        expect(response.body).to include 'Create your own account on openHPI.'
        expect(response.body).to include 'We found some errors'
        expect(response.body).to include 'The e-mail address you entered has already been registered.'
      end
    end
  end
end
