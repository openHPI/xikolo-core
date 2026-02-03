# frozen_string_literal: true

require 'spec_helper'
require 'active_job/test_helper'

describe 'Account Welcome Email', type: :request do
  include ActiveJob::TestHelper

  let(:user_id) { 'c088d006-8886-4b3c-a6ac-d45f168abc5b' }
  let(:confirmation_url) { 'https://xikolo.de/welcome_email' }

  before do
    Msgr.client.start
    clear_enqueued_jobs
  end

  describe '#welcome_email' do
    context 'when confirmation_url is present' do
      it 'enqueues SendWelcomeEmailJob with confirmation_url' do
        expect do
          Msgr.publish(
            {
              user_id: user_id,
              confirmation_url: confirmation_url,
            },
            to: 'xikolo.web.account.sign_up'
          )

          Msgr::TestPool.run
        end.to have_enqueued_job(NotificationService::SendWelcomeEmailJob)
          .with(user_id, confirmation_url)
      end
    end

    context 'when confirmation_url is missing' do
      it 'enqueues SendWelcomeEmailJob with nil confirmation_url' do
        expect do
          Msgr.publish(
            {
              user_id: user_id,
            },
            to: 'xikolo.web.account.sign_up'
          )

          Msgr::TestPool.run
        end.to have_enqueued_job(NotificationService::SendWelcomeEmailJob)
          .with(user_id, nil)
      end
    end
  end
end
