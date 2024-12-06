# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications: UserDisables: Create', type: :request do
  subject(:disable_notification) do
    post '/notification_user_settings/disable', params:
  end

  # Do not change the user id. See security_hash annotation for details.
  let(:user_id) { '11111111-2222-3333-4444-555555555555' }

  before do
    Stub.service(
      :account,
      email_url: '/emails/{id}',
      session_url: '/sessions/{id}'
    )
    Stub.request(
      :account, :get, "/user/#{user_id}"
    ).to_return Stub.json({
      id: user_id,
      preferences_url: "/user/#{user_id}/preferences",
    })
  end

  context 'without the required params' do
    let(:params) { {} }

    before { disable_notification }

    it 'renders an error message' do
      expect(response).to have_http_status :found
      expect(flash[:error].first).to eq 'The provided link seems to be invalid.'
    end
  end

  context 'with required params' do
    let(:params) do
      {email: user_email, hash: security_hash, key: notification_key}
    end
    let(:user_email) { 'john@example.com' }
    let(:security_hash) do
      # Do not change this hash (as it is generated from the email id and address)
      '88d9a72789e4c8c58b172ac6703c915d89af58c52f62eb40af175a4d4751e21a'
    end
    let(:notification_key) { 'announcement' }

    before do
      Stub.request(
        :account, :get, "/emails/#{user_email}"
      ).to_return Stub.json({
        # Do not change the email id. See security_hash annotation for details.
        id: '66666666-7777-8888-9999-000000000000',
        address: user_email,
        user_url: "/user/#{user_id}",
      })
    end

    context 'but invalid security hash' do
      let(:security_hash) { 'not_correct' }

      let!(:disable_stub) do
        Stub.request(:account, :patch, "/user/#{user_id}/preferences")
          .to_return Stub.json({})
      end

      before { disable_notification }

      it 'renders an error message' do
        expect(disable_stub).not_to have_been_requested
        expect(response).to have_http_status :found
        expect(flash[:error].first).to eq 'The provided link seems to be invalid.'
      end
    end

    context 'but invalid notification key' do
      let(:notification_key) { 'invalid_key' }

      it 'raises an error' do
        expect { disable_notification }.to raise_error KeyError
      end
    end

    describe '(notification types)' do
      shared_examples 'disables notification setting' do |settings_key|
        let!(:disable_stub) do
          Stub.request(:account, :patch, "/user/#{user_id}/preferences")
            .with(body: {properties: {settings_key => false}})
            .to_return Stub.json({})
        end

        before { disable_notification }

        it { expect(disable_stub).to have_been_requested }
      end

      context 'for (global) announcements' do
        let(:notification_key) { 'announcement' }

        include_examples 'disables notification setting',
          'notification.email.news.announcement'

        it 'informs the user about the disabled setting' do
          expect(flash[:success].first).to start_with \
            "Your account #{user_email} will not receive any more platform news."
        end

        context 'for key with trailing special character' do
          let(:notification_key) { 'announcement.' }

          include_examples 'disables notification setting',
            'notification.email.news.announcement'
        end
      end

      context 'for course announcements' do
        let(:notification_key) { 'course_announcement' }

        include_examples 'disables notification setting',
          'notification.email.course.announcement'

        it 'informs the user about the disabled setting' do
          expect(flash[:success].first).to start_with \
            "Your account #{user_email} will not receive any more course news."
        end
      end

      context 'for global (= all) email notifications' do
        let(:notification_key) { 'global' }

        include_examples 'disables notification setting',
          'notification.email.global'

        it 'informs the user about the disabled setting' do
          expect(flash[:success].first).to start_with \
            "Your account #{user_email} will not receive any more notifications via email."
        end
      end

      context 'for pinboard notifications' do
        let(:notification_key) { 'pinboard' }

        include_examples 'disables notification setting',
          'notification.email.pinboard.new_answer'

        it 'informs the user about the disabled setting' do
          expect(flash[:success].first).to start_with \
            "Your account #{user_email} will not receive any more pinboard news."
        end
      end
    end
  end
end
